# Lab 11 Defense Notes (plus existing Lab 10)

**Why call WidgetsFlutterBinding.ensureInitialized() before runApp?**
It allows Flutter plugins to initialize before we access SharedPreferences.
Then we await the saved theme before drawing the first screen, avoiding a
white flash when Dark Mode was saved.

**What is SharedPreferences?**
Simple local key-value storage for small non-sensitive data, not a database
or a secure password vault.

**Which keys are used?**
`app_theme_dark_mode` -> bool,
`user_display_name` -> String,
`offline_notes_json` -> JSON String.

**Why use ?? false and ?? 'Guest User'?**
If nothing has been saved, the app must start with safe default values.

**How do you save List<NoteItem>?**
Convert each note with `toJson()`, then call `jsonEncode()` on the whole
list, and store it via `prefs.setString(notesKey, jsonString)`.

**How do you restore notes?**
Read the JSON String using `prefs.getString(notesKey)`, call
`jsonDecode()`, then convert each object using `NoteItem.fromJson()`.

**How do Add, Toggle and Delete work?**
We change the in-memory list, notify listeners, and serialize the *entire*
updated list to SharedPreferences. Notes appear newest-first.

**Why a serialized write queue?**
Rapid changes must not allow an older JSON snapshot to be written after a
newer snapshot and accidentally restore deleted notes.

**What proves persistence?**
On Android: add notes, enable Dark Mode, save username, force-stop/kill
the app, then start it from the launcher. Hot Restart is NOT the same test.

**SharedPreferences vs Keychain / Keystore?**
SharedPreferences is for non-sensitive simple settings. Keychain/Keystore
are protected OS facilities intended for secret keys and credentials.

**Does this mean the entire store works offline?**
No. LW11 notes/settings are local and work offline; product data in Lab 10
still requires the network and has its own Retry screen.
