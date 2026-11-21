import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab10_from_lab9/providers/notes_vault_provider.dart';
import 'package:lab10_from_lab9/screens/notes_vault_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('username, new note and checkbox update the offline screen', (tester) async {
    final vault = await NotesVaultProvider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<NotesVaultProvider>.value(
        value: vault,
        child: const MaterialApp(home: NotesVaultScreen()),
      ),
    );
    expect(find.text('Hello, Guest User!'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('username-field')), 'Damir');
    await tester.tap(find.byKey(const ValueKey('save-username')));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Damir!'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('new-note-field')), 'My homework');
    // Scroll the action above the snackbar left by the username save.
    await tester.ensureVisible(find.byKey(const ValueKey('add-note')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -230));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    expect(find.text('My homework'), findsOneWidget);
    expect(vault.notes.length, 1);

    final noteId = vault.notes.single.id;
    await tester.ensureVisible(find.byKey(ValueKey('note-check-$noteId')));
    await tester.tap(find.byKey(ValueKey('note-check-$noteId')));
    await tester.pumpAndSettle();
    expect(vault.notes.single.isCompleted, isTrue);

    await tester.ensureVisible(find.byKey(ValueKey('note-delete-$noteId')));
    await tester.tap(find.byKey(ValueKey('note-delete-$noteId')));
    await tester.pumpAndSettle();
    expect(vault.notes, isEmpty);
    expect(find.text('No saved notes yet'), findsOneWidget);
  });
}
