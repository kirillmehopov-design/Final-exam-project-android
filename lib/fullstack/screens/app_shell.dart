part of '../shop_ui.dart';

class SneakerHubFullstackApp extends StatelessWidget {
  const SneakerHubFullstackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SneakerHub | Almaty',
      themeMode: themeMode,
      theme: SneakerDesign.theme(Brightness.light),
      darkTheme: SneakerDesign.theme(Brightness.dark),
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri == null) return null;
        final isCustom = uri.scheme == 'narxoz' && uri.host == 'store';
        final isWebPath = uri.pathSegments.length >= 3 &&
            uri.pathSegments.first == 'store';
        if (!isCustom && !isWebPath) return null;
        final pieces = uri.pathSegments;
        if (pieces.length < 2 || pieces[pieces.length - 2] != 'product') {
          return null;
        }
        final id = int.tryParse(pieces.last);
        if (id == null || id <= 0) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: context.read<ShopCubit>(),
            child: ProductPage(productId: id),
          ),
        );
      },
      home: BlocConsumer<ShopCubit, ShopState>(
        listenWhen: (before, after) =>
            before.notice != after.notice && after.notice != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.notice!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: state.error ? Colors.red.shade700 : null,
            ));
        },
        builder: (context, state) =>
            state.user == null ? const LoginPage() : const Dashboard(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'customer@demo.test');
  final password = TextEditingController(text: 'DemoPass123!');
  bool register = false;
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopCubit>().state;
    final desktop = MediaQuery.sizeOf(context).width >= 920;
    final login = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: desktop ? 48 : 24, vertical: 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!desktop) const Padding(
              padding: EdgeInsets.only(bottom: 34),
              child: Text('SNEAKERHUB', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900,
                  letterSpacing: -1.6))),
            SneakerDesign.eyebrow('Your sneaker universe'),
            const SizedBox(height: 12),
            Text(register ? 'Join the club.' : 'Welcome back.',
              style: TextStyle(fontSize: desktop ? 43 : 36, height: 1.08,
                letterSpacing: -2.0, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('Discover your next pair, explore Almaty showrooms and track orders.',
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: email, keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline),
                hintText: 'you@example.com')),
            const SizedBox(height: 18),
            const Text('Password', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: password, obscureText: !showPassword,
              onSubmitted: (_) {
                if (!state.busy) context.read<ShopCubit>().login(
                  email.text.trim(), password.text, register: register);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Your password',
                suffixIcon: IconButton(
                  tooltip: showPassword ? 'Hide password' : 'Show password',
                  icon: Icon(showPassword ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                  onPressed: () => setState(() => showPassword = !showPassword)),
              )),
            const SizedBox(height: 24),
            SizedBox(height: 54, child: FilledButton(
              onPressed: state.busy ? null : () => context.read<ShopCubit>().login(
                email.text.trim(), password.text, register: register),
              child: state.busy ? const SizedBox(height: 19, width: 19,
                child: CircularProgressIndicator(strokeWidth: 2))
                : Text(register ? 'Create my account' : 'Sign in to SneakerHub'),
            )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? 'Already a member? Sign in'
                : 'New here? Create an account'),
            ),
            const SizedBox(height: 18),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            Text('EXPLORE THE DEMO', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: [
                for (final role in ['customer', 'admin', 'courier'])
                  ActionChip(
                    label: Text(role == 'customer' ? 'Shopper' :
                      role == 'admin' ? 'Store admin' : 'Courier'),
                    avatar: Icon(role == 'customer' ? Icons.person_outline
                      : role == 'admin' ? Icons.inventory_2_outlined
                      : Icons.local_shipping_outlined, size: 17),
                    onPressed: () => setState(() {
                      register = false;
                      email.text = '$role@demo.test';
                      password.text = 'DemoPass123!';
                    }),
                  ),
              ]),
            const SizedBox(height: 20),
            Text('Educational prototype • No real purchases or deliveries',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
    return Scaffold(
      body: Row(children: [
        if (desktop)
          Expanded(child: ClipRRect(
            child: Stack(fit: StackFit.expand, children: [
              Image.network(
                'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1600&q=85',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF312E2A))),
              DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .12),
                    Colors.black.withValues(alpha: .82)]))),
              Padding(
                padding: const EdgeInsets.all(50),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SNEAKERHUB', style: TextStyle(color: Colors.white,
                    fontSize: 30, letterSpacing: -1.5, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  const Text('NOT JUST SHOES.\nA WAY OF LIFE.',
                    style: TextStyle(color: Colors.white, fontSize: 56, height: 1.03,
                      fontWeight: FontWeight.w900, letterSpacing: -2)),
                  const SizedBox(height: 16),
                  const Text('12 curated styles · 10 Almaty demo stores',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                ]),
              ),
            ]),
          )),
        Expanded(child: login),
      ]),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) context.read<ShopCubit>().pollUpdates();
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShopCubit>();
    final state = context.watch<ShopCubit>().state;
    final role = state.user?['role'] as String? ?? 'customer';
    final desktop = MediaQuery.sizeOf(context).width >= 1230;
    final customer = role == 'customer';
    final admin = role == 'admin';
    final screens = admin
        ? <Widget>[const InventoryPage(), const OrdersPage(),
            const StatsPage(), const ProfilePage()]
        : role == 'courier'
            ? <Widget>[const OrdersPage(), const ProfilePage()]
            : <Widget>[const CatalogPage(), const FavoritesPage(),
                const StoresPage(), const CartPage(), const OrdersPage(),
                const ProfilePage()];
    final names = admin
        ? ['Stock', 'Orders', 'Analytics', 'Account']
        : role == 'courier'
            ? ['Deliveries', 'Account']
            : ['Discover', 'Saved', 'Stores', 'Bag', 'Orders', 'Account'];
    final icons = admin
        ? [Icons.inventory_2_outlined, Icons.receipt_long_outlined,
            Icons.analytics_outlined, Icons.person_outline]
        : role == 'courier'
            ? [Icons.local_shipping_outlined, Icons.person_outline]
            : [Icons.grid_view_rounded, Icons.favorite_outline,
                Icons.location_on_outlined, Icons.shopping_bag_outlined,
                Icons.receipt_long_outlined, Icons.person_outline];
    final selected = state.tab.clamp(0, screens.length - 1);
    final count = state.cart.fold<int>(0, (n, item) => n + item.quantity);
    final bottomIndices = customer ? [0, 2, 1, 3, 4]
        : List<int>.generate(screens.length, (i) => i);
    final barSelected = bottomIndices.contains(selected)
        ? bottomIndices.indexOf(selected) : 0;

    Widget menuItem(int index) {
      final active = selected == index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: active ? SneakerDesign.orange
              : Theme.of(context).colorScheme.onSurface,
            backgroundColor: active
              ? SneakerDesign.lime.withValues(alpha: .45) : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => cubit.selectTab(index),
          child: Text(names[index], style: TextStyle(fontWeight: active
            ? FontWeight.w900 : FontWeight.w600)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 73,
        titleSpacing: desktop ? 32 : 18,
        title: InkWell(
          onTap: () => cubit.selectTab(0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome_rounded, color: SneakerDesign.ink, size: 27),
            const SizedBox(width: 4),
            Text('SNEAKERHUB.', style: TextStyle(
              fontSize: desktop ? 22 : 18, letterSpacing: -1.1,
              fontWeight: FontWeight.w900)),
          ]),
        ),
        actions: [
          if (desktop) ...[
            for (var i = 0; i < names.length; i++)
              if (i != names.length - 1 && !(customer && i == 3))
                menuItem(i),
            const SizedBox(width: 16),
          ],
          if (customer)
            IconButton(
              tooltip: 'Shopping bag',
              onPressed: () => cubit.selectTab(3),
              icon: Badge(isLabelVisible: count > 0,
                label: Text('$count'), child: const Icon(Icons.shopping_bag_outlined)),
            ),
          IconButton(
            tooltip: 'Refresh products and orders',
            icon: state.busy ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
            onPressed: state.busy ? null : cubit.refresh,
          ),
          IconButton(
            tooltip: 'Account & notifications',
            icon: Icon(selected == screens.length - 1
              ? Icons.account_circle : Icons.account_circle_outlined),
            onPressed: () => cubit.selectTab(screens.length - 1),
          ),
          SizedBox(width: desktop ? 26 : 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(31),
          child: Container(height: 31, width: double.infinity,
            color: SneakerDesign.lime,
            alignment: Alignment.center,
            child: Text(desktop
              ? 'SNEAKERHUB  /  ALMATY          10 CONCEPT STORES          CLICK & COLLECT  •  DELIVERY ESTIMATES'
              : '10 ALMATY DEMO STORES  •  FIND YOUR SIZE',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: SneakerDesign.ink,
                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.25))),
        ),
      ),
      body: Column(children: [
        Expanded(child: IndexedStack(index: selected, children: screens)),
        if (desktop && selected != 0) const SneakerSiteFooter(compact: true),
      ]),
      bottomNavigationBar: desktop ? null : NavigationBar(
        selectedIndex: barSelected,
        onDestinationSelected: (index) => cubit.selectTab(bottomIndices[index]),
        destinations: [
          for (final index in bottomIndices)
            NavigationDestination(
              icon: index == 3 && customer
                ? Badge(isLabelVisible: count > 0,
                    label: Text('$count'), child: Icon(icons[index]))
                : Icon(icons[index]),
              selectedIcon: Icon(icons[index], color: SneakerDesign.ink),
              label: names[index],
            ),
        ],
      ),
    );
  }
}
