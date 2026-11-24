import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lab10_from_lab9/models/note_item.dart';
import 'package:lab10_from_lab9/providers/notes_vault_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('NoteItem toJson and fromJson keep all four fields', () {
    const original = NoteItem(
      id: 'n1',
      title: 'Study Flutter',
      dateText: '2026-11-20 09:30',
      isCompleted: true,
    );
    final decoded = NoteItem.fromJson(original.toJson());
    expect(decoded.id, 'n1');
    expect(decoded.title, 'Study Flutter');
    expect(decoded.dateText, '2026-11-20 09:30');
    expect(decoded.isCompleted, isTrue);
  });

  test('defaults are false, Guest User, and empty notes', () async {
    final vault = await NotesVaultProvider.load();
    expect(vault.isDarkMode, isFalse);
    expect(vault.displayName, 'Guest User');
    expect(vault.notes, isEmpty);
    vault.dispose();
  });

  test('saves theme, username, and JSON notes; restores on reload', () async {
    final vault = await NotesVaultProvider.load();
    await vault.setDarkMode(true);
    await vault.saveDisplayName('Damir');
    await vault.addNote('First note');
    await vault.addNote('Second note');
    final firstId = vault.notes.first.id;
    final secondId = vault.notes.last.id;
    expect(vault.notes.first.title, 'Second note');
    await vault.toggleNote(firstId);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(NotesVaultProvider.themeKey), isTrue);
    expect(prefs.getString(NotesVaultProvider.displayNameKey), 'Damir');
    final savedJson = prefs.getString(NotesVaultProvider.notesKey)!;
    final savedList = jsonDecode(savedJson) as List<dynamic>;
    expect(savedList.length, 2);
    expect(savedList.first['isCompleted'], isTrue);
    final restored = await NotesVaultProvider.load();
    expect(restored.isDarkMode, isTrue);
    expect(restored.displayName, 'Damir');
    expect(restored.notes.length, 2);
    expect(restored.notes.first.isCompleted, isTrue);
    await restored.deleteNote(secondId);
    final restoredAfterDelete = await NotesVaultProvider.load();
    expect(restoredAfterDelete.notes.length, 1);
    expect(restoredAfterDelete.notes.single.title, 'Second note');
    vault.dispose();
    restored.dispose();
    restoredAfterDelete.dispose();
  });

  test('invalid JSON is ignored rather than crashing on startup', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotesVaultProvider.notesKey, '{broken');
    final vault = await NotesVaultProvider.load();
    expect(vault.notes, isEmpty);
    vault.dispose();
  });
}
