import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shop_cubit.dart';
import '../providers/theme_cubit.dart';

String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
int amount(Json p) => p['sale_price_cents'] as int;

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

Widget photo(String url, {double height = 170}) => Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height, color: const Color(0xFFE8EAF0),
        alignment: Alignment.center, child: const Icon(Icons.image_not_supported_outlined, size: 42)),
    );

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String query = '';
  String brand = 'All';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopCubit>().state;
    if (state.catalogLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.catalogError != null && state.products.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Unable to load products'),
          const SizedBox(height: 8),
          Text(state.catalogError!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<ShopCubit>().retryCatalog(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ));
    }
    final brands = ['All', ...state.products.map((p) => p['brand'] as String).toSet()];
    final filtered = state.products.where((p) =>
        ('$query'.isEmpty || (p['name'] as String).toLowerCase().contains(query.toLowerCase())) &&
        (brand == 'All' || p['brand'] == brand)).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 950 ? 4 : constraints.maxWidth > 580 ? 3 : 2;
      return RefreshIndicator(
        onRefresh: () => context.read<ShopCubit>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Discover sneakers', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) setState(() => query = value);
              });
            },
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
                hintText: 'Search by model...', filled: true, border: OutlineInputBorder())),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final value in brands)
                Padding(padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(value), selected: brand == value,
                    onSelected: (_) => setState(() => brand = value))),
            ])),
          ]),
        )),
        if (filtered.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32),
            child: Center(child: Text('No sneakers found')))),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: constraints.maxWidth < 380 ? .65 : .75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = filtered[index];
              return ProductTile(product: product);
            }, childCount: filtered.length),
          ),
        ),
          ]),
      );
    });
  }
}

class ProductTile extends StatelessWidget {
  final Json product;
  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<ShopCubit>().state.favorites.contains(product['id']);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BlocProvider.value(
            value: context.read<ShopCubit>(),
            child: ProductPage(productId: product['id'] as int)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Stack(fit: StackFit.expand, children: [
            photo(product['image_url'] as String, height: 220),
            if ((product['discount'] as int) > 0)
              Positioned(top: 8, left: 8, child: Chip(label: Text('-${product['discount']}%'))),
            Positioned(top: 3, right: 3, child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black),
                onPressed: () => context.read<ShopCubit>().toggleFavorite(product['id'] as int)),
            )),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(product['brand'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(money(amount(product)),
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF243A76))),
            ])),
        ]),
      ),
    );
  }
}

class ProductPage extends StatefulWidget {
  final int productId;
  const ProductPage({super.key, required this.productId});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int? size;
  Future<List<Json>>? reviewFuture;
  @override
  void initState() {
    super.initState();
    reviewFuture = context.read<ShopCubit>().reviews(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final product = cubit.product(widget.productId);
    if (product == null) return const Scaffold(body: Center(child: Text('Product not found')));
    final sizes = Map<String, dynamic>.from(product['sizes'] as Map);
    final inStock = sizes.entries.where((e) => (e.value as int) > 0)
        .map((e) => int.parse(e.key)).toList()..sort();
    final selectedSize = inStock.contains(size) ? size : (inStock.isEmpty ? null : inStock.first);
    final isFavorite = cubit.state.favorites.contains(widget.productId);
    return Scaffold(
      appBar: AppBar(title: const Text('Product details'), actions: [
        IconButton(icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: () => cubit.toggleFavorite(widget.productId)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(borderRadius: BorderRadius.circular(22),
              child: photo(product['image_url'] as String, height: 290)),
            const SizedBox(height: 18),
            Text(product['name'] as String, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(money(amount(product)), style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF243A76), fontWeight: FontWeight.bold)),
            if ((product['discount'] as int) > 0)
              Text('${product['discount']}% discount from ${money(product['price_cents'] as int)}'),
            const SizedBox(height: 12),
            Text(product['description'] as String),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              Chip(label: Text(product['brand'] as String)),
              Chip(label: Text(product['category'] as String)),
              Chip(label: Text('${product['review_count']} reviews')),
            ]),
            const SizedBox(height: 12),
            const Text('Choose size', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final s in inStock)
                ChoiceChip(label: Text('$s'), selected: selectedSize == s,
                  onSelected: (_) => setState(() => size = s)),
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: selectedSize == null ? null : () {
              cubit.addToCart(widget.productId, selectedSize);
              Navigator.pop(context);
              cubit.selectTab(2);
            }, icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to cart')),
            const Divider(height: 36),
            Row(children: [
              const Expanded(child: Text('Customer reviews', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
              TextButton(onPressed: () => _writeReview(context), child: const Text('Write review')),
            ]),
            FutureBuilder<List<Json>>(future: reviewFuture, builder: (context, snap) {
              if (snap.hasError) return Text('${snap.error}');
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.isEmpty) return const Text('No reviews yet. Reviews require delivered purchases.');
              return Column(children: [
                for (final review in snap.data!) ListTile(
                  title: Text('★ ${review['rating']}  ${review['email']}'),
                  subtitle: Text(review['comment'] as String)),
              ]);
            }),
          ]))),
      ]),
    );
  }

  Future<void> _writeReview(BuildContext context) async {
    final text = TextEditingController();
    var rating = 5;
    final result = await showDialog<(int, String)>(context: context, builder: (context) =>
      StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Review purchased sneakers'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(initialValue: rating,
            items: [for (int n = 1; n <= 5; n++) DropdownMenuItem(value: n, child: Text('$n stars'))],
            onChanged: (v) => setDialogState(() => rating = v ?? 5)),
          TextField(controller: text, minLines: 2, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Your review')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, (rating, text.text)),
            child: const Text('Submit')),
        ],
      )));
    if (!mounted || result == null) return;
    await context.read<ShopCubit>().submitReview(widget.productId, result.$1, result.$2);
    if (mounted) setState(() => reviewFuture = context.read<ShopCubit>().reviews(widget.productId));
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopCubit>().state;
    final saved = s.products.where((p) => s.favorites.contains(p['id'])).toList();
    if (saved.isEmpty) return const Center(child: Text('No favorites yet. Tap hearts in the shop.'));
    return LayoutBuilder(builder: (context, box) => GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: box.maxWidth > 800 ? 4 : box.maxWidth > 500 ? 3 : 2,
        childAspectRatio: .75, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: saved.length,
      itemBuilder: (context, i) => ProductTile(product: saved[i]),
    ));
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final cart = cubit.state.cart;
    final total = cart.fold<int>(0, (v, item) {
      final product = cubit.product(item.productId);
      return v + (product == null ? 0 : amount(product) * item.quantity);
    });
    if (cart.isEmpty) return const Center(child: Text('Your cart is empty'));
    return Column(children: [
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: cart.length,
        itemBuilder: (context, index) {
          final item = cart[index];
          final p = cubit.product(item.productId);
          if (p == null) return const SizedBox.shrink();
          return Card(child: ListTile(
            leading: SizedBox(width: 64, child: photo(p['image_url'] as String, height: 64)),
            title: Text(p['name'] as String),
            subtitle: Text('Size ${item.size} • ${money(amount(p))}'),
            trailing: SizedBox(width: 132, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => cubit.changeQuantity(item, item.quantity - 1)),
              Text('${item.quantity}'),
              IconButton(icon: const Icon(Icons.add_circle_outline),
                onPressed: () => cubit.changeQuantity(item, item.quantity + 1)),
            ])),
          ));
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: Text('Subtotal ${money(total)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        FilledButton(onPressed: cubit.state.busy ? null : () => _checkout(context),
          child: const Text('Checkout')),
      ]))),
    ]);
  }

  Future<void> _checkout(BuildContext context) async {
    final address = TextEditingController(text: '123 Demo Street, Almaty');
    final promo = TextEditingController();
    var usePoints = false;
    final order = await showDialog<(String, String, bool)>(context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Confirm demo order'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No real payment will be collected.'),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Delivery address')),
          TextField(controller: promo, decoration: const InputDecoration(labelText: 'Promo code (WELCOME10)')),
          CheckboxListTile(value: usePoints, title: const Text('Use loyalty points'),
            onChanged: (v) => setDialogState(() => usePoints = v ?? false)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, (address.text, promo.text, usePoints)),
            child: const Text('Place order')),
        ],
      )));
    if (order != null && context.mounted) {
      await context.read<ShopCubit>().checkout(order.$1, order.$2, order.$3);
    }
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final role = cubit.state.user?['role'] as String? ?? 'customer';
    final orders = cubit.state.orders;
    if (orders.isEmpty) return const Center(child: Text('No orders yet'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final id = order['id'] as int;
        final status = order['status'] as String;
        final items = asJsonList(order['items']);
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Order #$id', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Chip(label: Text(status.replaceAll('_', ' '))),
            ]),
            Text('${order['address']}'),
            const SizedBox(height: 6),
            for (final item in items) Text('${item['name']} • EU ${item['size']} × ${item['quantity']}'),
            const SizedBox(height: 8),
            Text(money(order['total_cents'] as int),
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (role == 'customer' && status == 'arrived')
              FilledButton.icon(icon: const Icon(Icons.pin), label: const Text('Show delivery code'),
                onPressed: () => _showCode(context, id)),
            if (role == 'admin' && status == 'placed')
              FilledButton(onPressed: () => cubit.adminStatus(id, 'preparing'),
                child: const Text('Start preparing')),
            if (role == 'admin' && status == 'preparing')
              FilledButton(onPressed: cubit.state.couriers.isEmpty ? null : () =>
                cubit.adminStatus(id, 'out_for_delivery',
                  courierId: cubit.state.couriers.first['id'] as int),
                child: const Text('Assign courier & dispatch')),
            if (role == 'courier' && status == 'out_for_delivery')
              FilledButton(onPressed: () => cubit.courierArrive(id),
                child: const Text('I have arrived (demo)')),
            if (role == 'courier' && status == 'arrived')
              FilledButton(onPressed: () => _verifyCode(context, id),
                child: const Text('Enter customer code')),
          ],
        )));
      });
  }

  Future<void> _showCode(BuildContext context, int id) async {
    try {
      final code = await context.read<ShopCubit>().customerCode(id);
      if (!context.mounted) return;
      await showDialog<void>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Delivery code (20 minutes)'),
        content: SelectableText(code, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, letterSpacing: 6, fontWeight: FontWeight.bold)),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Close'))],
      ));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _verifyCode(BuildContext context, int id) async {
    final field = TextEditingController();
    final code = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('One-time handoff code'),
      content: TextField(controller: field, keyboardType: TextInputType.number,
        maxLength: 6, decoration: const InputDecoration(labelText: '6 digits from customer')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialog, field.text), child: const Text('Verify')),
      ],
    ));
    if (code != null && context.mounted) await context.read<ShopCubit>().courierDeliver(id, code);
  }
}

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ShopCubit>().state.products;
    return ListView(padding: const EdgeInsets.all(12), children: [
      const Padding(padding: EdgeInsets.all(8), child: Text('Warehouse / Supplies',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      for (final p in products) Card(child: Padding(padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (final e in Map<String, dynamic>.from(p['sizes'] as Map).entries)
              Chip(label: Text('${e.key}: ${e.value}')),
          ]),
          Text('Discount: ${p['discount']}%'),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(icon: const Icon(Icons.add_box_outlined),
              label: const Text('Receive supply'), onPressed: () => _supply(context, p)),
            OutlinedButton.icon(icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Set discount'), onPressed: () => _discount(context, p)),
          ]),
        ]))),
    ]);
  }

  Future<void> _supply(BuildContext context, Json product) async {
    final stock = Map<String, dynamic>.from(product['sizes'] as Map);
    var size = int.parse(stock.keys.first);
    final quantity = TextEditingController(text: '5');
    final result = await showDialog<(int, int)>(context: context,
      builder: (dialog) => StatefulBuilder(builder: (dialog, setDialog) => AlertDialog(
        title: const Text('Receive stock'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(initialValue: size,
            items: [for (final s in stock.keys) DropdownMenuItem(value: int.parse(s), child: Text('EU $s'))],
            onChanged: (v) => setDialog(() => size = v ?? size)),
          TextField(controller: quantity, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, (size, int.tryParse(quantity.text) ?? 0)),
            child: const Text('Add supply')),
        ],
      )));
    if (result != null && context.mounted) {
      await context.read<ShopCubit>().restock(product['id'] as int, result.$1, result.$2);
    }
  }

  Future<void> _discount(BuildContext context, Json p) async {
    final field = TextEditingController(text: '${p['discount']}');
    final percent = await showDialog<int>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Discount (%)'),
      content: TextField(controller: field, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '0 to 90')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialog, int.tryParse(field.text)),
          child: const Text('Save')),
      ],
    ));
    if (percent != null && context.mounted) {
      await context.read<ShopCubit>().changeDiscount(p['id'] as int, percent);
    }
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<ShopCubit>().state.stats;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Store dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: const Icon(Icons.receipt), title: const Text('Total orders'),
        trailing: Text('${stats['orders'] ?? 0}'))),
      Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Delivered revenue'),
        trailing: Text(money((stats['revenue_cents'] ?? 0) as int)))),
      Card(child: ListTile(leading: const Icon(Icons.warning_amber), title: const Text('Low-stock size variants'),
        trailing: Text('${stats['low_stock_variants'] ?? 0}'))),
    ]);
  }
}

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
