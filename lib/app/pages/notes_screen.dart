import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/notes_service.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/app/widgets/edit_note_dialog.dart';
import 'package:my_quran/quran/quran.dart';

enum NotesSort { updatedDesc, updatedAsc, createdDesc, createdAsc }

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _notesService = NotesService();

  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  List<VerseNote> _all = [];

  String _query = '';
  int? _surahFilter; // null = all
  NotesSort _sort = NotesSort.updatedDesc;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      setState(() => _query = _searchController.text.trim());
    });
  }

  Future<void> _load() async {
    final notes = await _notesService.getAllNotes();
    if (!mounted) return;
    setState(() {
      _all = notes;
      _loading = false;
    });
  }

  List<VerseNote> get _filtered {
    Iterable<VerseNote> items = _all;

    if (_surahFilter != null) {
      items = items.where((n) => n.surah == _surahFilter);
    }

    if (_query.isNotEmpty) {
      final q = _query;
      items = items.where((n) => n.text.contains(q));
    }

    final list = items.toList();
    list.sort((a, b) {
      int cmpDate(DateTime x, DateTime y) => x.compareTo(y);

      switch (_sort) {
        case NotesSort.updatedDesc:
          return cmpDate(b.updatedAt, a.updatedAt);
        case NotesSort.updatedAsc:
          return cmpDate(a.updatedAt, b.updatedAt);
        case NotesSort.createdDesc:
          return cmpDate(b.createdAt, a.createdAt);
        case NotesSort.createdAsc:
          return cmpDate(a.createdAt, b.createdAt);
      }
    });

    return list;
  }

  Future<void> _edit(VerseNote note) async {
    final res = await showEditNoteDialog(
      context,
      initialText: note.text,
      canDelete: true,
    );
    if (res == null) return;

    if (res.action == NoteDialogAction.delete) {
      await _notesService.removeNoteById(note.id);
    } else {
      await _notesService.updateNote(note.copyWith(text: res.text));
    }
    await _load();
  }

  String _sortLabel(NotesSort s) {
    return switch (s) {
      NotesSort.updatedDesc => 'آخر تعديل (الأحدث)',
      NotesSort.updatedAsc => 'آخر تعديل (الأقدم)',
      NotesSort.createdDesc => 'تاريخ الإنشاء (الأحدث)',
      NotesSort.createdAsc => 'تاريخ الإنشاء (الأقدم)',
    };
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? labelText,
    IconData? prefixIconData,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIconData != null ? Icon(prefixIconData) : null,
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.applyOpacity(0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملاحظات'),
          actions: [
            PopupMenuButton<NotesSort>(
              tooltip: 'الترتيب',
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => NotesSort.values
                  .map(
                    (s) => PopupMenuItem(value: s, child: Text(_sortLabel(s))),
                  )
                  .toList(),
              icon: const Icon(Icons.sort),
            ),
          ],
        ),

        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: _inputDecoration(
                        prefixIconData: Icons.search,
                        hintText: 'ابحث داخل الملاحظات...',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: DropdownButtonFormField<int?>(
                      initialValue: _surahFilter,
                      decoration: _inputDecoration(labelText: 'تصفية بالسورة'),
                      items: [
                        const DropdownMenuItem<int?>(child: Text('كل السور')),
                        for (int s = 1; s <= 114; s++)
                          DropdownMenuItem<int?>(
                            value: s,
                            child: Text(
                              'سورة ${Quran.instance.getSurahNameArabic(s)}',
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _surahFilter = v),
                    ),
                  ),
                  if (_surahFilter != null)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _surahFilter = null;
                      }),
                      icon: const Icon(Icons.filter_list_off_outlined),
                      label: const Text('إلغاء التصفية'),
                    ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('لا توجد ملاحظات'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final n = items[i];
                              final surahName = Quran.instance
                                  .getSurahNameArabic(n.surah);

                              return Card(
                                elevation: 0,
                                child: ListTile(
                                  title: Text(
                                    n.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'سورة $surahName •'
                                    ' الآية ${getArabicNumber(n.verse)}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _edit(n),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
