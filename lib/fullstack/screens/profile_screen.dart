part of '../shop_ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final user = cubit.state.user ?? {};
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Center(child: Icon(Icons.account_circle, size: 80)),
      const SizedBox(height: 12),
      Center(child: Text('${user['email']}', style: const TextStyle(fontWeight: FontWeight.bold))),
      Center(child: Text('Role: ${user['role']}')),
      const SizedBox(height: 12),
      SwitchListTile(
        secondary: const Icon(Icons.dark_mode_outlined),
        title: const Text('Dark theme'),
        value: context.watch<ThemeCubit>().state == ThemeMode.dark,
        onChanged: (enabled) => context.read<ThemeCubit>().setDarkMode(enabled),
      ),
      Card(child: ListTile(leading: const Icon(Icons.workspace_premium_outlined),
        title: const Text('Loyalty points'), trailing: Text('${user['points'] ?? 0}'))),
      const SizedBox(height: 20),
      Text('In-app notifications (${cubit.state.notifications.where((n) => n['is_read'] == 0).length} unread)',
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (cubit.state.notifications.isEmpty) const Text('No notifications yet.'),
      for (final note in cubit.state.notifications)
        Card(child: ListTile(
          leading: Icon(note['is_read'] == 0 ? Icons.notifications_active : Icons.notifications_none),
          title: Text(note['title'] as String), subtitle: Text(note['message'] as String),
          trailing: note['is_read'] == 0
            ? IconButton(icon: const Icon(Icons.done), tooltip: 'Mark read',
                onPressed: () => cubit.markRead(note['id'] as int)) : null,
        )),
      const SizedBox(height: 18),
      OutlinedButton.icon(onPressed: () => cubit.logout(),
        icon: const Icon(Icons.logout), label: const Text('Sign out')),
    ]);
  }
}
