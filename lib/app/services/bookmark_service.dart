// lib/app/services/bookmark_service.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_quran/app/models.dart';

class BookmarkService {
  factory BookmarkService() => _instance;
  BookmarkService._internal();
  static final BookmarkService _instance = BookmarkService._internal();

  static const String _bookmarksKey = 'verse_bookmarks';
  static const String _categoriesKey = 'bookmark_categories';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ──────────────────────────────────────────────
  // Default categories
  // ──────────────────────────────────────────────

  static final List<BookmarkCategory> defaultCategories = [
    const BookmarkCategory(id: 'default', title: 'عام', color: Colors.blue),
    const BookmarkCategory(
      id: 'memorization',
      title: 'حفظ',
      color: Colors.green,
    ),
    const BookmarkCategory(id: 'review', title: 'مراجعة', color: Colors.orange),
    const BookmarkCategory(id: 'tafsir', title: 'تفسير', color: Colors.purple),
  ];

  static BookmarkCategory get _defaultCategory =>
      defaultCategories.firstWhere((c) => c.id == 'default');

  // ──────────────────────────────────────────────
  // Categories CRUD
  // ──────────────────────────────────────────────

  Future<List<BookmarkCategory>> getCategories() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_categoriesKey);
    if (raw == null) {
      // First time: persist defaults then return them
      await _saveCategories(defaultCategories);
      return List.from(defaultCategories);
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final categories = decoded
        .map((e) => BookmarkCategory.fromJson(e as Map<String, dynamic>))
        .toList();

    // Safety: ensure default exists
    if (!categories.any((c) => c.id == 'default')) {
      categories.insert(0, _defaultCategory);
      await _saveCategories(categories);
    }

    return categories;
  }

  Future<BookmarkCategory?> getCategoryById(String id) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BookmarkCategory> getCategoriesSync() {
    final raw = _prefs?.getString(_categoriesKey);
    if (raw == null) return List.from(defaultCategories);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final categories = decoded
        .map((e) => BookmarkCategory.fromJson(e as Map<String, dynamic>))
        .toList();

    if (!categories.any((c) => c.id == 'default')) {
      return [_defaultCategory, ...categories];
    }
    return categories;
  }

  Future<void> addCategory(BookmarkCategory category) async {
    final categories = await getCategories();
    if (categories.any((c) => c.id == category.id)) return;
    categories.add(category);
    await _saveCategories(categories);
  }

  Future<void> updateCategory(BookmarkCategory category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index == -1) return;
    categories[index] = category;
    await _saveCategories(categories);
  }

  Future<void> removeCategory(String categoryId) async {
    if (categoryId == 'default') return;

    final categories = await getCategories();
    categories.removeWhere((c) => c.id == categoryId);
    await _saveCategories(categories);

    final bookmarks = await getBookmarks();
    final updated = bookmarks.map((b) {
      if ((b.categoryId ?? 'default') == categoryId) {
        return b.copyWith(categoryId: () => 'default');
      }
      return b;
    }).toList();
    await _saveBookmarks(updated);
  }

  /// Ensures:
  /// - unique IDs
  /// - default category exists
  Future<void> replaceCategories(List<BookmarkCategory> categories) async {
    final unique = <String, BookmarkCategory>{};
    for (final c in categories) {
      unique[c.id] = c;
    }
    unique.putIfAbsent('default', () => _defaultCategory);

    final normalized = unique.values.toList()
      ..sort((a, b) {
        if (a.id == 'default') return -1;
        if (b.id == 'default') return 1;
        return a.title.compareTo(b.title);
      });

    await _saveCategories(normalized);
  }

  Future<void> _saveCategories(List<BookmarkCategory> categories) async {
    final prefs = await _preferences;
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesKey, encoded);
  }

  // ──────────────────────────────────────────────
  // Bookmarks CRUD
  // ──────────────────────────────────────────────

  Future<List<VerseBookmark>> getBookmarks() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_bookmarksKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => VerseBookmark.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<VerseBookmark> getBookmarksSync() {
    final raw = _prefs?.getString(_bookmarksKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => VerseBookmark.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  bool isBookmarked(int surah, int verse) {
    final bookmarks = getBookmarksSync();
    return bookmarks.any((b) => b.surah == surah && b.verse == verse);
  }

  VerseBookmark? getBookmarkFor(int surah, int verse) {
    final bookmarks = getBookmarksSync();
    try {
      return bookmarks.firstWhere((b) => b.surah == surah && b.verse == verse);
    } catch (_) {
      return null;
    }
  }

  VerseBookmark _normalizeBookmark(VerseBookmark b) {
    final cat = (b.categoryId == null || b.categoryId!.trim().isEmpty)
        ? 'default'
        : b.categoryId!;
    return b.copyWith(categoryId: () => cat);
  }

  Future<void> addBookmark(VerseBookmark bookmark) async {
    final bookmarks = await getBookmarks();

    final now = DateTime.now();
    final normalized = _normalizeBookmark(bookmark);

    final existingIndex = bookmarks.indexWhere(
      (b) => b.surah == normalized.surah && b.verse == normalized.verse,
    );

    if (existingIndex != -1) {
      final existing = bookmarks[existingIndex];

      // preserve identity + original createdAt, update updatedAt
      bookmarks[existingIndex] = normalized.copyWith(
        id: existing.id,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
    } else {
      bookmarks.add(normalized.copyWith(updatedAt: now));
    }

    await _saveBookmarks(bookmarks);
  }

  Future<void> updateBookmark(VerseBookmark bookmark) async {
    final bookmarks = await getBookmarks();
    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index == -1) return;

    final now = DateTime.now();
    final normalized = _normalizeBookmark(bookmark);

    bookmarks[index] = normalized.copyWith(updatedAt: now);
    await _saveBookmarks(bookmarks);
  }

  Future<void> removeBookmarkByVerse(int surah, int verse) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.surah == surah && b.verse == verse);
    await _saveBookmarks(bookmarks);
  }

  Future<void> removeBookmarkById(String id) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await _saveBookmarks(bookmarks);
  }

  Future<List<VerseBookmark>> getBookmarksByCategory(String categoryId) async {
    final bookmarks = await getBookmarks();
    final cid = categoryId.trim().isEmpty ? 'default' : categoryId;
    return bookmarks.where((b) => (b.categoryId ?? 'default') == cid).toList();
  }

  /// OPTION A: Replace bookmarks wholesale (used by backup import).
  /// Ensures:
  /// - one bookmark per verse (dedupe)
  /// - categoryId normalized
  Future<void> replaceBookmarks(List<VerseBookmark> bookmarks) async {
    final map = <String, VerseBookmark>{};
    for (final b in bookmarks) {
      final nb = _normalizeBookmark(b);
      map['${nb.surah}:${nb.verse}'] = nb; // keep last wins
    }
    await _saveBookmarks(map.values.toList());
  }

  Future<void> _saveBookmarks(List<VerseBookmark> bookmarks) async {
    final prefs = await _preferences;
    final encoded = jsonEncode(bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_bookmarksKey, encoded);
  }
}
