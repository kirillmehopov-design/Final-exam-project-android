part of '../shop_ui.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String query = '';
  String brand = 'All';
  String category = 'All';
  String sortBy = 'Recommended';
  bool offersOnly = false;
  bool inStockOnly = false;
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
    final brands = ['All', ...state.products.map((p) => p['brand'] as String).toSet()]..sort();
    final categories = ['All', ...state.products.map((p) => p['category'] as String).toSet()]..sort();
    final filtered = state.products.where((p) {
      final text = (p['name'] as String).toLowerCase();
      final brandText = (p['brand'] as String).toLowerCase();
      final matchesQuery = query.trim().isEmpty ||
          text.contains(query.toLowerCase().trim()) ||
          brandText.contains(query.toLowerCase().trim());
      final available = Map<String, dynamic>.from(p['sizes'] as Map)
          .values.any((q) => (q as num).toInt() > 0);
      return matchesQuery &&
          (brand == 'All' || p['brand'] == brand) &&
          (category == 'All' || p['category'] == category) &&
          (!offersOnly || (p['discount'] as int) > 0) &&
          (!inStockOnly || available);
    }).toList();
    switch (sortBy) {
      case 'Price: low to high':
        filtered.sort((a, b) => amount(a).compareTo(amount(b)));
        break;
      case 'Price: high to low':
        filtered.sort((a, b) => amount(b).compareTo(amount(a)));
        break;
      case 'Biggest discount':
        filtered.sort((a, b) => (b['discount'] as int).compareTo(a['discount'] as int));
        break;
    }
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 950 ? 4 : constraints.maxWidth > 580 ? 3 : 2;
      return RefreshIndicator(
        onRefresh: () => context.read<ShopCubit>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
        if (state.catalogLoading)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(),
          ),
        if (state.catalogError != null)
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Network request failed. Showing cached results if available.'),
                    const SizedBox(height: 6),
                    Text(
                      state.catalogError!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.read<ShopCubit>().retryCatalog(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111D3F), Color(0xFF3756A4)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SNEAKERHUB / ALMATY',
                    style: TextStyle(color: Color(0xFFAFC5FF), letterSpacing: 1.6, fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                const Text('Your next pair starts here.',
                    style: TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('${state.products.length} sneaker styles • prices in ₸ • demo checkout',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70)),
                    onPressed: () => context.read<ShopCubit>().selectTab(2),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Find 10 Almaty demo stores')),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Text('Discover sneakers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800))),
              Text('${filtered.length} results',
                style: Theme.of(context).textTheme.bodySmall),
            ]),
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
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(width: 170, child: DropdownButtonFormField<String>(
                value: category, isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Category', isDense: true, border: OutlineInputBorder()),
                items: [for (final value in categories)
                  DropdownMenuItem(value: value, child: Text(value))],
                onChanged: (v) => setState(() => category = v ?? 'All'),
              )),
              SizedBox(width: 190, child: DropdownButtonFormField<String>(
                value: sortBy, isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Sort', isDense: true, border: OutlineInputBorder()),
                items: [for (final value in const [
                    'Recommended', 'Price: low to high', 'Price: high to low', 'Biggest discount'])
                  DropdownMenuItem(value: value, child: Text(value))],
                onChanged: (v) => setState(() => sortBy = v ?? 'Recommended'),
              )),
              FilterChip(
                label: const Text('On sale'), selected: offersOnly,
                onSelected: (v) => setState(() => offersOnly = v)),
              FilterChip(
                label: const Text('In stock'), selected: inStockOnly,
                onSelected: (v) => setState(() => inStockOnly = v)),
            ]),
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
