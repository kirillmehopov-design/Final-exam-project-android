import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_vault_provider.dart';

/// LW11: offline notes and settings, responsive on mobile and tablet.
class NotesVaultScreen extends StatefulWidget {
  const NotesVaultScreen({super.key});

  @override
  State<NotesVaultScreen> createState() => _NotesVaultScreenState();
}

class _NotesVaultScreenState extends State<NotesVaultScreen> {
  late final TextEditingController _usernameController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final savedName = context.read<NotesVaultProvider>().displayName;
    _usernameController = TextEditingController(
      text: savedName == 'Guest User' ? '' : savedName,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final vault = context.read<NotesVaultProvider>();
    try {
      await vault.saveDisplayName(_usernameController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username saved on this device')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save username')),
      );
    }
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    try {
      await context.read<NotesVaultProvider>().addNote(text);
      if (mounted) _noteController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save note')),
      );
    }
  }

  Future<void> _toggleNote(String id) async {
    try {
      await context.read<NotesVaultProvider>().toggleNote(id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save note change')),
      );
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await context.read<NotesVaultProvider>().deleteNote(id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete note from storage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<NotesVaultProvider>();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes & Settings'),
        actions: const [
          Icon(Icons.offline_pin_outlined),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Text(
                  'Hello, ${vault.displayName}!',
                  key: const ValueKey('vault-welcome'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your theme, profile and notes are stored on this device. '
                  'Notes work without internet.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Card(
                  child: SwitchListTile.adaptive(
                    key: const ValueKey('dark-mode-toggle'),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Remember theme after restart'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: vault.isDarkMode,
                    onChanged: (value) async {
                      try {
                        await vault.setDarkMode(value);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not save theme')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text('User Profile', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('username-field'),
                  controller: _usernameController,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onSubmitted: (_) => _saveUsername(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const ValueKey('save-username'),
                    onPressed: _saveUsername,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Username'),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Text('My Notes',
                      style: Theme.of(context).textTheme.titleLarge)),
                    Text('${vault.notes.length} saved',
                      style: TextStyle(color: colors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('new-note-field'),
                  controller: _noteController,
                  maxLength: 140,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'New note',
                    hintText: 'Prepare for Flutter defense',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_add_outlined),
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const ValueKey('add-note'),
                    onPressed: _addNote,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Note'),
                  ),
                ),
                const SizedBox(height: 12),
                if (vault.notes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 44),
                          SizedBox(height: 8),
                          Text('No saved notes yet'),
                          Text('Add your first note above'),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vault.notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final note = vault.notes[index];
                      return Card(
                        key: ValueKey('note-card-${note.id}'),
                        child: ListTile(
                          leading: Checkbox(
                            key: ValueKey('note-check-${note.id}'),
                            value: note.isCompleted,
                            onChanged: (_) => _toggleNote(note.id),
                          ),
                          title: Text(
                            note.title,
                            style: TextStyle(
                              decoration: note.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text(note.dateText),
                          trailing: IconButton(
                            key: ValueKey('note-delete-${note.id}'),
                            tooltip: 'Delete ${note.title}',
                            onPressed: () => _deleteNote(note.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
