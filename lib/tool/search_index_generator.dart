// ignore_for_file: avoid_print ()

import 'dart:convert';
import 'dart:io';

import 'package:my_quran/app/search/processor.dart';

/// Generates search indexes for multiple narrations.
/// Run with: dart run search_index_generator.dart
void main() async {
  // 1. Generate HAFS Index
  await _generateIndexForNarration(
    label: 'HAFS',
    inputFiles: ['assets/quran.json'],
    outputFile: 'assets/search_index_hafs.json',
  );

  print('------------------------------------------------');

  // 2. Generate WARSH Index (Uses Warsh text)
  await _generateIndexForNarration(
    label: 'WARSH',
    inputFiles: ['assets/warsh.json'],
    outputFile: 'assets/search_index_warsh.json',
  );
}

Future<void> _generateIndexForNarration({
  required String label,
  required List<String> inputFiles,
  required String outputFile,
}) async {
  print('🔨 [$label] Building search index...');

  // Map<normalized_word, Set<verse_id>>
  final Map<String, Set<int>> invertedIndex = {};
  int filesProcessed = 0;

  for (final filePath in inputFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️ Warning: $filePath not found. Skipping.');
      continue;
    }

    print('   📄 Processing $filePath...');
    final String content = await file.readAsString();
    final Map<String, dynamic> data =
        jsonDecode(content) as Map<String, dynamic>;

    // Iterate Surahs
    for (final surahEntry in data.entries) {
      final surahNumber = int.parse(surahEntry.key);
      final verses = surahEntry.value as Map<String, dynamic>;

      // Iterate Verses
      for (final verseEntry in verses.entries) {
        final verseNumber = int.parse(verseEntry.key);
        final text = verseEntry.value.toString();

        // Create unique verse ID
        final verseId = surahNumber * 1000 + verseNumber;

        // Process text
        _processVerseText(text, verseId, invertedIndex);
      }
    }
    filesProcessed++;
  }

  if (filesProcessed == 0) {
    print('❌ Error: No input files were processed for $label.');
    return;
  }

  // Sort keys for binary search optimization
  final sortedKeys = invertedIndex.keys.toList()..sort();

  // Convert sets to sorted lists for JSON
  final indexData = <String, List<int>>{};
  for (final key in sortedKeys) {
    indexData[key] = invertedIndex[key]!.toList()..sort();
  }

  // Create final output
  final output = {'keys': sortedKeys, 'data': indexData};

  // Write to file
  final out = File(outputFile);
  await out.writeAsString(jsonEncode(output));

  print('✅ [$label] Index generated!');
  print('📊 Keywords: ${sortedKeys.length}');
  print('📝 Output: ${out.path}');
}

/// Process verse text and add to inverted index
void _processVerseText(
  String text,
  int verseId,
  Map<String, Set<int>> invertedIndex,
) {
  // inside _processVerseText
  final tokens = ArabicTextProcessor.tokenize(text);

  for (final token in tokens) {
    final normalized = ArabicTextProcessor.normalize(token);
    if (normalized.isEmpty) continue;

    if (RegExp(r'[\u0621-\u064A]').hasMatch(normalized)) {
      invertedIndex.putIfAbsent(normalized, () => <int>{});
      invertedIndex[normalized]!.add(verseId);
    }
  }
}
