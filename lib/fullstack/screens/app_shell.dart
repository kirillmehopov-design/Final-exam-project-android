part of '../shop_ui.dart';

class SneakerHubFullstackApp extends StatelessWidget {
  const SneakerHubFullstackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        title: 'SneakerHub',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF17213B)),
          scaffoldBackgroundColor: const Color(0xFFF7F8FB),
          cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7289FA),
            brightness: Brightness.dark,
          ),
        ),
        home: BlocConsumer<ShopCubit, ShopState>(
          listenWhen: (previous, current) => previous.notice != current.notice && current.notice != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice!),
                backgroundColor: state.error ? Colors.red.shade700 : null));
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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopCubit>().state;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.shopping_bag_rounded, size: 68, color: Color(0xFF17213B)),
              const SizedBox(height: 12),
              Text('SneakerHub', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Sneaker marketplace • REST API • SQLite • BLoC',
                textAlign: TextAlign.center),
              const SizedBox(height: 28),
              TextField(controller: email,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.busy ? null : () => context.read<ShopCubit>().login(
                  email.text.trim(), password.text, register: register),
                child: Text(register ? 'Create account' : 'Sign in'),
              ),
              TextButton(onPressed: () => setState(() => register = !register),
                child: Text(register ? 'Already registered? Sign in' : 'Create a customer account')),
              const Divider(height: 30),
              const Text('Demo accounts (password: DemoPass123!)', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                for (final role in ['customer', 'admin', 'courier'])
                  OutlinedButton(onPressed: () {
                    setState(() {
                      register = false;
                      email.text = '$role@demo.test';
                      password.text = 'DemoPass123!';
                    });
                  }, child: Text(role.toUpperCase())),
              ]),
              const SizedBox(height: 8),
              const Text('Demo only. Start the FastAPI server first. No real payments or push notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopCubit>().state;
    final role = state.user?['role'] as String? ?? 'customer';
    final isAdmin = role == 'admin';
    final isCourier = role == 'courier';
    final screens = isAdmin
        ? <Widget>[const InventoryPage(), const OrdersPage(), const StatsPage(), const ProfilePage()]
        : isCourier
            ? <Widget>[const OrdersPage(), const ProfilePage()]
            : <Widget>[const CatalogPage(), const FavoritesPage(), const CartPage(),
                const OrdersPage(), const ProfilePage()];
    final tabs = isAdmin
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ]
        : isCourier
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Deliveries'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ]
            : [
                const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shop'),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: state.favorites.isNotEmpty,
                    label: Text('${state.favorites.length}'),
                    child: const Icon(Icons.favorite_border),
                  ),
                  label: 'Saved',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: state.cart.isNotEmpty,
                    label: Text('${state.cart.fold<int>(0, (total, item) => total + item.quantity)}'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ];
    final selected = state.tab.clamp(0, screens.length - 1);
    return Scaffold(
      appBar: AppBar(
        title: Text('SNEAKERHUB  •  ${role.toUpperCase()}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (state.busy) const Padding(padding: EdgeInsets.all(12),
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          IconButton(tooltip: 'Refresh from API', icon: const Icon(Icons.refresh),
            onPressed: state.busy ? null : () => context.read<ShopCubit>().refresh()),
        ],
      ),
      body: IndexedStack(index: selected, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        currentIndex: selected,
        onTap: context.read<ShopCubit>().selectTab,
        items: tabs,
      ),
    );
  }
}
