import 'dart:convert';

import 'package:my_quran/app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NotesService {
  factory NotesService() => _instance;
  NotesService._internal();
  static final NotesService _instance = NotesService._internal();

  static const String _notesKey = 'verse_notes';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<VerseNote>> getAllNotes() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_notesKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => VerseNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VerseNote>> getNotesForVerse(int surah, int verse) async {
    final all = await getAllNotes();
    return all.where((n) => n.surah == surah && n.verse == verse).toList();
  }

  Future<VerseNote> addNote({
    required int surah,
    required int verse,
    required String text,
  }) async {
    final now = DateTime.now();
    final note = VerseNote(
      id: const Uuid().v4(),
      surah: surah,
      verse: verse,
      text: text,
      createdAt: now,
      updatedAt: now,
    );

    final notes = await getAllNotes();
    notes.add(note);
    await _save(notes);
    return note;
  }

  Future<void> updateNote(VerseNote note) async {
    final notes = await getAllNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx == -1) return;
    notes[idx] = note.copyWith(updatedAt: DateTime.now());
    await _save(notes);
  }

  Future<void> removeNoteById(String id) async {
    final notes = await getAllNotes();
    notes.removeWhere((n) => n.id == id);
    await _save(notes);
  }

  Future<void> replaceAll(List<VerseNote> notes) async {
    await _save(List<VerseNote>.from(notes));
  }

  Future<void> _save(List<VerseNote> notes) async {
    final prefs = await _preferences;
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_notesKey, encoded);
  }
}
