part of '../shop_ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final user = cubit.state.user ?? <String, dynamic>{};
    final email = user['email'] as String? ?? 'SneakerHub member';
    final role = user['role'] as String? ?? 'customer';
    final unread = cubit.state.notifications
      .where((n) => n['is_read'] == 0).length;
    final dark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return ListView(children: [
      Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SneakerDesign.eyebrow('Your SneakerHub'),
              const SizedBox(height: 8),
              Text('My account.',
                style: TextStyle(fontSize: MediaQuery.sizeOf(context).width < 600
                    ? 32 : 44,
                  fontWeight: FontWeight.w900, letterSpacing: -1.6)),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: SneakerDesign.graphite,
                  borderRadius: BorderRadius.circular(6)),
                child: Wrap(
                  runSpacing: 20, spacing: 20,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: SneakerDesign.lime,
                        child: Text(email[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 24,
                            color: SneakerDesign.ink)),
                      ),
                      const SizedBox(width: 13),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WELCOME TO THE CLUB',
                            style: TextStyle(color: SneakerDesign.lime,
                              fontSize: 10, letterSpacing: 1.4,
                              fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          SizedBox(width: MediaQuery.sizeOf(context).width < 390
                              ? 185 : 280,
                            child: Text(email, maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white,
                                fontSize: 15, fontWeight: FontWeight.bold))),
                          Text('Role: ${role.toUpperCase()}',
                            style: const TextStyle(color: Colors.white70,
                              fontSize: 11)),
                        ]),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SNEAKER POINTS',
                        style: TextStyle(color: Colors.white70,
                          letterSpacing: 1.4, fontSize: 10)),
                      const SizedBox(height: 6),
                      Text('${user['points'] ?? 0} PTS',
                        style: const TextStyle(color: SneakerDesign.lime,
                          fontSize: 25, fontWeight: FontWeight.w900)),
                    ]),
                  ]),
              ),
              const SizedBox(height: 26),
              Text('Preferences & services',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark appearance'),
                    subtitle: const Text('Saved for your next visit'),
                    value: dark,
                    onChanged: (v) =>
                      context.read<ThemeCubit>().setDarkMode(v),
                  ),
                  const Divider(height: 1),
                  if (role == 'customer') ...[
                    ListTile(
                      leading: const Icon(Icons.swap_horiz_rounded),
                      title: const Text('Store transfers'),
                      subtitle: const Text('Track requests between Almaty shops'),
                      trailing: const Icon(Icons.arrow_outward),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(builder: (_) =>
                          BlocProvider.value(
                            value: context.read<ShopCubit>(),
                            child: const TransferRequestsPage()))),
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.note_alt_outlined),
                    title: const Text('Offline notes & settings'),
                    subtitle: const Text('Lab 11 • Saved on this device'),
                    trailing: const Icon(Icons.arrow_outward),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(builder: (_) =>
                          ChangeNotifierProvider<NotesVaultProvider>.value(
                            value: context.read<NotesVaultProvider>(),
                            child: Consumer<NotesVaultProvider>(
                              builder: (_, vault, __) => Theme(
                                data: vault.isDarkMode
                                  ? ThemeData.dark(useMaterial3: true)
                                  : ThemeData.light(useMaterial3: true),
                                child: const NotesVaultScreen()),
                            ),
                          )),
                      );
                      if (context.mounted) {
                        await context.read<ThemeCubit>().setDarkMode(
                          context.read<NotesVaultProvider>().isDarkMode);
                      }
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 29),
              Row(children: [
                Expanded(child: Text('Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: SneakerDesign.lime,
                    borderRadius: BorderRadius.circular(40)),
                  child: Text('$unread unread',
                    style: const TextStyle(color: SneakerDesign.ink,
                      fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 11),
              if (cubit.state.notifications.isEmpty)
                Card(child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 24),
                  child: Row(children: [
                    const Icon(Icons.notifications_none, size: 27),
                    const SizedBox(width: 14),
                    Expanded(child: Text('You are all caught up. Stock, discount '
                        'and order updates will show up here.',
                      style: Theme.of(context).textTheme.bodyMedium)),
                  ]),
                )),
              for (final note in cubit.state.notifications)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                      leading: Icon(note['is_read'] == 0
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none,
                        color: note['is_read'] == 0
                          ? SneakerDesign.ink : null),
                      title: Text(note['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text(note['message'] as String),
                      trailing: note['is_read'] == 0
                        ? IconButton(
                          tooltip: 'Mark as read',
                          icon: const Icon(Icons.done_all),
                          onPressed: () =>
                            cubit.markRead(note['id'] as int))
                        : null,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Align(alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => cubit.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                )),
            ],
          ),
        ),
      )),
      const SneakerSiteFooter(),
    ]);
  }
}
