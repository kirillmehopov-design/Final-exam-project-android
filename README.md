# Cloud Product Explorer + LW11 Offline Notes & Settings

This repository extends the existing Flutter Lab 9+10 store (Fake Store API,
Hero product detail, gallery and global cart). **LW11 adds a responsive local
Notes & Settings screen**, available via the note icon in the Catalog AppBar.
The original store and its tests remain in place.

## LW11 requirements coverage (10/10 source-code rubric)

- **Theme (2.5):** `WidgetsFlutterBinding.ensureInitialized()` and
  `await NotesVaultProvider.load()` in `main()` occur BEFORE `runApp()`.
  `ThemeMode` is based on the preloaded `app_theme_dark_mode` boolean;
  the switch writes with `SharedPreferences.setBool`.
- **Profile (2.5):** username TextField + Save Username.
  `getString('user_display_name') ?? 'Guest User'` on startup;
  `setString` on Save.
- **Notes (3.0):** `NoteItem` has `id`, `title`, `dateText`,
  `isCompleted`, `toJson()` and `fromJson()`. Full list is saved under
  `offline_notes_json` with `jsonEncode()` and loaded with `jsonDecode()`.
  New notes are prepended; checkbox toggles completion; delete removes note.
- **Cold restart (2.0):** values are read from disk before first render.
  Demonstrate on a **real phone or Android/iOS emulator**; do NOT use Hot
  Restart as evidence.

## Run in Android Studio

From project root:

```powershell
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test
flutter run
```

Use an Android emulator or phone for the instructor's force-quit test.
If you only want to preview in Chrome, run:

```powershell
flutter create --platforms=web .
flutter run -d chrome
```

Chrome storage is browser-specific and **does not replace the mobile
force-quit demonstration**.

## Live defense demo

1. Open the store. Tap the **note icon** in the top app bar.
2. Switch **Dark Mode ON**. The entire app theme changes.
3. Type a username and press **Save Username**.
4. Add **two notes**, check one as completed. Both must appear in newest-first order.
5. **Completely terminate the app process** from the mobile app switcher or device
   settings (not Flutter Hot Restart). Reopen from the launcher.
6. Open the note icon again: the dark theme, username, the two notes and
   completion state must still be visible.
7. Delete one note, terminate and reopen again: the deleted note must not return.
8. Turn off network: Notes & Settings remains accessible, even if the
   Fake Store catalog shows an error.

## Why use SharedPreferences?

It stores **small, non-sensitive key-value data** on the device. We store a
bool for theme, String for username, and a JSON String for the notes list.
It is not secure encrypted storage: do NOT store passwords, access tokens
or other secrets here. Use iOS Keychain / Android Keystore-backed secure
storage for sensitive data. SharedPreferences is not a durable transactional
database and is not intended for high-volume or critical records.

## Files

```text
lib/
  main.dart
  models/note_item.dart
  providers/notes_vault_provider.dart
  screens/notes_vault_screen.dart
  ...existing Lab 9+10 store modules...
test/
  notes_vault_test.dart
  notes_vault_widget_test.dart
  ...existing Lab 9+10 tests...
```

**Testing status:** source tests included; actual Flutter SDK execution and
force-kill/reopen verification must be performed locally in Android Studio.
