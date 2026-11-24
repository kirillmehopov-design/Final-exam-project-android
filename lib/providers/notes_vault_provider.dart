import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_item.dart';

/// LW11: settings and notes stored on-device; never requires the internet.
class NotesVaultProvider extends ChangeNotifier {
  NotesVaultProvider._(
    this._preferences,
    this._isDarkMode,
    this._displayName,
    this._notes,
  );

  static const String themeKey = 'app_theme_dark_mode';
  static const String displayNameKey = 'user_display_name';
  static const String notesKey = 'offline_notes_json';

  final SharedPreferences _preferences;
  bool _isDarkMode;
  String _displayName;
  final List<NoteItem> _notes;
  int _nextNoteId = 0;
  Future<void> _notesWriteQueue = Future<void>.value();

  bool get isDarkMode => _isDarkMode;
  String get displayName => _displayName;
  List<NoteItem> get notes => List<NoteItem>.unmodifiable(_notes);

  /// main() awaits load() BEFORE runApp(): no white flash in dark mode.
  static Future<NotesVaultProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(displayNameKey) ?? 'Guest User';
    return NotesVaultProvider._(
      prefs,
      prefs.getBool(themeKey) ?? false,
      savedName.trim().isEmpty ? 'Guest User' : savedName,
      decodeNotes(prefs.getString(notesKey)),
    );
  }

  /// Missing or corrupted offline data must not crash app startup.
  static List<NoteItem> decodeNotes(String? savedJson) {
    if (savedJson == null || savedJson.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(savedJson);
      if (decoded is! List) return [];
      final notes = <NoteItem>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          final note = NoteItem.fromJson(Map<String, dynamic>.from(entry));
          if (note.id.isNotEmpty && note.title.trim().isNotEmpty) {
            notes.add(note);
          }
        } catch (_) {
          // Skip one broken entry, preserve all other valid notes.
        }
      }
      return notes;
    } catch (_) {
      return [];
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final success = await _preferences.setBool(themeKey, value);
    if (!success) throw StateError('Failed to save dark mode');
  }

  Future<void> saveDisplayName(String value) async {
    final trimmed = value.trim();
    _displayName = trimmed.isEmpty ? 'Guest User' : trimmed;
    notifyListeners();
    final success = await _preferences.setString(displayNameKey, _displayName);
    if (!success) throw StateError('Failed to save display name');
  }

  Future<void> addNote(String title) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return;
    final now = DateTime.now();
    _notes.insert(
      0,
      NoteItem(
        id: '${now.microsecondsSinceEpoch}-${_nextNoteId++}',
        title: cleaned,
        dateText: '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)} '
            '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}',
        isCompleted: false,
      ),
    );
    notifyListeners();
    await _persistNotes();
  }

  Future<void> toggleNote(String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index < 0) return;
    final note = _notes[index];
    _notes[index] = note.copyWith(isCompleted: !note.isCompleted);
    notifyListeners();
    await _persistNotes();
  }

  Future<void> deleteNote(String id) async {
    final before = _notes.length;
    _notes.removeWhere((note) => note.id == id);
    if (_notes.length == before) return;
    notifyListeners();
    await _persistNotes();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _persistNotes() {
    // All notes become ONE JSON string. Queue writes so rapid toggles do
    // not let an old snapshot overwrite the newest note list on disk.
    final snapshot = jsonEncode(_notes.map((note) => note.toJson()).toList());
    final write = _notesWriteQueue.then((_) async {
      final saved = await _preferences.setString(notesKey, snapshot);
      if (!saved) throw StateError('Failed to save notes locally');
    });
    _notesWriteQueue = write.catchError((Object _) {});
    return write;
  }
}
