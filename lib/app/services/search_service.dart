import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/search/processor.dart';

typedef PlainVerseProvider = String Function(int surah, int verse);

class SearchService {
  static List<String> _sortedKeys = [];

  static Map<String, dynamic> _indexData = {};
  static Map<String, List<int>> _bigramToKeyIndexes = {};
  static bool _bigramsReady = false;

  static PlainVerseProvider? _plainVerseProvider;

  // ignore: avoid_setters_without_getters ()
  static set plainVerseProvider(PlainVerseProvider provider) {
    _plainVerseProvider = provider;
  }

  // Track current loaded type to avoid reloading the same file
  static String _currentType = '';
  static bool isReady = false;

  /// Initialize or Switch Index
  /// [fontFamily]: 'hafs', 'warsh', 'rustam', etc.
  static Future<void> init(String fontFamily) async {
    // Determine target file
    String targetFile;
    if (fontFamily.toLowerCase() == 'warsh') {
      targetFile = 'assets/search_index_warsh.json';
    } else {
      // Default to Hafs for 'hafs', 'rustam', or anything else
      targetFile = 'assets/search_index_hafs.json';
    }

    // Optimization: Don't reload if we already have this index
    if (isReady && _currentType == targetFile) return;

    isReady = false;
    _bigramsReady = false;
    _bigramToKeyIndexes = {};
    _currentType = targetFile;

    try {
      final jsonString = await rootBundle.loadString(targetFile);

      // Parse in Isolate
      final data = await compute(_parseJson, jsonString);

      _sortedKeys = (data['keys'] as List).cast<String>();
      _indexData = data['data'] as Map<String, dynamic>;

      // Build bigram index (for contains) in isolate
      _bigramToKeyIndexes = await compute(_buildBigramIndex, _sortedKeys);
      _bigramsReady = true;

      isReady = true;
      debugPrint('🔍 Search index loaded: $targetFile ✅');
    } catch (e) {
      debugPrint('❌ Error loading search index: $e');
      isReady = false;
    }
  }

  static Map<String, List<int>> _buildBigramIndex(List<String> keys) {
    final map = <String, List<int>>{};

    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (k.length < 2) continue;

      final grams = <String>{};
      for (int j = 0; j < k.length - 1; j++) {
        grams.add(k.substring(j, j + 2));
      }

      for (final g in grams) {
        (map[g] ??= <int>[]).add(i);
      }
    }

    // lists are naturally sorted by i increasing
    return map;
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static const int defaultMaxHits = 200;

  static Future<SearchResponse> search(
    String rawQuery, {
    SearchMatchMode mode = SearchMatchMode.auto,
    SearchOperator operator = SearchOperator.and,
    bool fallbackToOrIfEmpty = true,
    int maxHits = defaultMaxHits,
  }) async {
    if (!isReady || rawQuery.trim().isEmpty) {
      return const SearchResponse(
        hits: [],
        effectiveMode: SearchMatchMode.auto,
        normalizedQueryTokens: <String>{},
        operatorUsed: SearchOperator.and,
        totalHits: 0,
        isTruncated: false,
      );
    }

    final rawTokens = ArabicTextProcessor.tokenize(rawQuery);
    final queryTokens = rawTokens
        .map(ArabicTextProcessor.normalize)
        .where((t) => t.isNotEmpty)
        .toList();

    if (queryTokens.isEmpty) {
      return const SearchResponse(
        hits: [],
        effectiveMode: SearchMatchMode.auto,
        normalizedQueryTokens: <String>{},
        operatorUsed: SearchOperator.and,
        totalHits: 0,
        isTruncated: false,
      );
    }

    final effectiveMode = _resolveEffectiveMode(mode, queryTokens);

    final tokenSets = queryTokens
        .map((t) => _findMatchesForSingleToken(t, mode: effectiveMode))
        .toList();

    Set<int> ids;
    var operatorUsed = operator;

    if (operator == SearchOperator.and) {
      ids = tokenSets.first;
      for (var i = 1; i < tokenSets.length; i++) {
        ids = ids.intersection(tokenSets[i]);
      }

      if (ids.isEmpty && fallbackToOrIfEmpty) {
        operatorUsed = SearchOperator.or;
        final union = <int>{};
        tokenSets.forEach(union.addAll);
        ids = union;
      }
    } else {
      final union = <int>{};
      tokenSets.forEach(union.addAll);
      ids = union;
    }

    // Sort IDs deterministically (surah then verse)
    final sortedIds = ids.toList()
      ..sort((a, b) {
        final as = a ~/ 1000;
        final av = a % 1000;
        final bs = b ~/ 1000;
        final bv = b % 1000;
        if (as != bs) return as.compareTo(bs);
        return av.compareTo(bv);
      });

    final totalHits = sortedIds.length;
    final isTruncated = totalHits > maxHits;
    final limitedIds = isTruncated
        ? sortedIds.take(maxHits).toList()
        : sortedIds;

    // If no provider, return hits without indices
    final provider = _plainVerseProvider;
    if (provider == null) {
      final hits = limitedIds.map((id) {
        final surah = id ~/ 1000;
        final verse = id % 1000;
        return SearchHit(
          surah: surah,
          verse: verse,
          matchedWordIndexes: const [],
        );
      }).toList();

      return SearchResponse(
        hits: hits,
        effectiveMode: effectiveMode,
        normalizedQueryTokens: queryTokens.toSet(),
        operatorUsed: operatorUsed,
        totalHits: totalHits,
        isTruncated: isTruncated,
      );
    }

    // Prepare payload (only for limited hits)
    final versesPayload = limitedIds.map((id) {
      final surah = id ~/ 1000;
      final verse = id % 1000;
      return <String, dynamic>{'id': id, 'plain': provider(surah, verse)};
    }).toList();

    final req = <String, dynamic>{
      'mode': effectiveMode.index,
      'queryTokens': queryTokens.toSet().toList(),
      'verses': versesPayload,
    };

    // Compute match indexes in isolate
    final computed = await compute(_computeMatchIndexesBatch, req);

    final map = (computed as Map).map<int, List<int>>(
      (k, v) => MapEntry(k as int, (v as List).cast<int>()),
    );

    final hits = limitedIds.map((id) {
      final surah = id ~/ 1000;
      final verse = id % 1000;
      return SearchHit(
        surah: surah,
        verse: verse,
        matchedWordIndexes: map[id] ?? const [],
      );
    }).toList();
    if (kDebugMode) {
      // Log a few cases where we returned a verse but couldn't find match indexes.
      final empties = hits.where((h) => h.matchedWordIndexes.isEmpty).take(5);
      for (final h in empties) {
        final plain = provider(h.surah, h.verse);
        debugPrint(
          'NO HIGHLIGHT: ${h.surah}:${h.verse} '
          'mode=$effectiveMode query=$queryTokens\n'
          'plain="$plain"\n'
          'plainTokensNorm=${ArabicTextProcessor.tokenize(plain).map(ArabicTextProcessor.normalize).toList()}',
        );
      }
    }
    return SearchResponse(
      hits: hits,
      effectiveMode: effectiveMode,
      normalizedQueryTokens: queryTokens.toSet(),
      operatorUsed: operatorUsed,
      totalHits: totalHits,
      isTruncated: isTruncated,
    );
  }

  /// isolate entrypoint
  static Map<int, List<int>> _computeMatchIndexesBatch(
    Map<String, dynamic> req,
  ) {
    final mode = SearchMatchMode.values[req['mode'] as int];
    final queryTokens = (req['queryTokens'] as List).cast<String>().toSet();
    final verses = (req['verses'] as List).cast<Map<String, dynamic>>();

    final out = <int, List<int>>{};
    for (final v in verses) {
      final id = v['id'] as int;
      final plain = v['plain'] as String;

      out[id] = _matchIndexesInPlainVerse(
        plainText: plain,
        queryTokens: queryTokens,
        mode: mode,
      );
    }
    return out;
  }

  static SearchMatchMode _resolveEffectiveMode(
    SearchMatchMode mode,
    List<String> queryTokens,
  ) {
    if (mode != SearchMatchMode.auto) return mode;

    final minLen = queryTokens
        .map((t) => t.length)
        .reduce((a, b) => a < b ? a : b);
    if (minLen == 2) return SearchMatchMode.contains;
    if (minLen <= 1) return SearchMatchMode.prefix;
    return SearchMatchMode.flexible;
  }

  static Set<int> _findMatchesForSingleToken(
    String token, {
    required SearchMatchMode mode,
  }) {
    return switch (mode) {
      SearchMatchMode.exact => _exact(token),
      SearchMatchMode.prefix => _prefix(token),
      SearchMatchMode.contains => _contains(token),
      SearchMatchMode.flexible => _flexible(token),
      SearchMatchMode.auto => _prefix(token), // auto is resolved earlier
    };
  }

  static Set<int> _exact(String token) {
    final results = <int>{};
    final v = _indexData[token];
    if (v is List) results.addAll(v.cast<int>());
    return results;
  }

  static Set<int> _prefix(String token) {
    final results = <int>{};

    // exact
    results.addAll(_exact(token));

    // prefix scan via sorted keys
    final startIndex = lowerBound(_sortedKeys, token);
    for (int i = startIndex; i < _sortedKeys.length; i++) {
      final key = _sortedKeys[i];
      if (!key.startsWith(token)) break;
      if (key == token) continue;
      final v = _indexData[key];
      if (v is List) results.addAll(v.cast<int>());
    }
    return results;
  }

  static Set<int> _contains(String token) {
    // if bigrams not ready, degrade gracefully
    if (!_bigramsReady || token.length < 2) {
      return _prefix(token);
    }

    // candidate keys via bigram intersection
    final grams = <String>[];
    for (int i = 0; i < token.length - 1; i++) {
      grams.add(token.substring(i, i + 2));
    }

    List<int>? candidates;
    for (final g in grams) {
      final list = _bigramToKeyIndexes[g];
      if (list == null) return <int>{}; // no keys contain this bigram
      candidates = candidates == null
          ? list
          : _intersectSorted(candidates, list);
      if (candidates.isEmpty) return <int>{};
    }

    final results = <int>{};
    for (final keyIndex in candidates!) {
      final key = _sortedKeys[keyIndex];
      if (!key.contains(token)) continue;
      final v = _indexData[key];
      if (v is List) results.addAll(v.cast<int>());
    }
    return results;
  }

  static Set<int> _flexible(String token) {
    // Query variants: original + remove common leading clitics (one step)
    final variants = <String>{token};

    const clitics = ['و', 'ف', 'ب', 'ك', 'ل', 'س'];
    for (final c in clitics) {
      if (token.startsWith(c) && token.length > 2) {
        variants.add(token.substring(1));
      }
    }

    // Optional: if query starts with "ال", allow without it (conservative)
    if (token.startsWith('ال') && token.length >= 4) {
      variants.add(token.substring(2));
    }

    final results = <int>{};
    for (final v in variants) {
      results.addAll(_prefix(v));
    }
    return results;
  }

  static List<int> _intersectSorted(List<int> a, List<int> b) {
    final out = <int>[];
    int i = 0;
    int j = 0;
    while (i < a.length && j < b.length) {
      final x = a[i];
      final y = b[j];
      if (x == y) {
        out.add(x);
        i++;
        j++;
      } else if (x < y) {
        i++;
      } else {
        j++;
      }
    }
    return out;
  }

  /// Produces indexes into "content words" (marks-only tokens removed).
  static List<int> _matchIndexesInPlainVerse({
    required String plainText,
    required Set<String> queryTokens,
    required SearchMatchMode mode,
  }) {
    final tokens = ArabicTextProcessor.tokenize(plainText);

    // contentWordsNormalized aligns with indexing normalization
    final contentWordsNormalized = <String>[];
    for (final t in tokens) {
      final n = ArabicTextProcessor.normalize(t);
      if (n.isEmpty) continue;
      // keep only Arabic-ish tokens
      if (!RegExp(r'[\u0621-\u064A]').hasMatch(n)) continue;
      contentWordsNormalized.add(n);
    }

    final matched = <int>{};

    bool matchesToken(String word, String q) {
      return switch (mode) {
        SearchMatchMode.exact => word == q,
        SearchMatchMode.prefix => word.startsWith(q),
        SearchMatchMode.contains => word.contains(q),
        SearchMatchMode.flexible => word.startsWith(
          q,
        ), // flexible handled via q-variants below
        SearchMatchMode.auto => word.startsWith(q),
      };
    }

    // For flexible: add query variants (clitics/al-)
    final qSet = (mode == SearchMatchMode.flexible)
        ? _queryVariants(queryTokens)
        : queryTokens;

    for (var i = 0; i < contentWordsNormalized.length; i++) {
      final w = contentWordsNormalized[i];
      for (final q in qSet) {
        if (q.isEmpty) continue;
        if (matchesToken(w, q)) {
          matched.add(i);
          break;
        }
      }
    }

    final out = matched.toList()..sort();
    return out;
  }

  static Set<String> _queryVariants(Set<String> base) {
    final out = <String>{...base};

    const clitics = ['و', 'ف', 'ب', 'ك', 'ل', 'س'];
    for (final q in base) {
      if (q.length <= 2) continue;

      if (q.startsWith('ال') && q.length >= 4) {
        out.add(q.substring(2));
      }

      for (final c in clitics) {
        if (q.startsWith(c) && q.length > 2) {
          out.add(q.substring(1));
        }
      }
    }
    return out;
  }
}
