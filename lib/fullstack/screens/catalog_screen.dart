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
  String sortBy = 'Featured';
  bool offersOnly = false;
  bool inStockOnly = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
    query = '';
    brand = 'All';
    category = 'All';
    sortBy = 'Featured';
    offersOnly = false;
    inStockOnly = false;
    _searchController.clear();
  });

  final _searchController = TextEditingController();
  Widget _hero(BuildContext context, double width) {
    final narrow = width < 670;
    final heroHeight = narrow ? 325.0 : 385.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: heroHeight,
        child: Stack(fit: StackFit.expand, children: [
          Image.network(
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1600&q=85',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF554D43)),
          ),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.black.withValues(alpha: .88),
              Colors.black.withValues(alpha: narrow ? .44 : .05)],
          ))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: narrow ? 25 : 53,
              vertical: narrow ? 24 : 44),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SNEAKERHUB  /  ALMATY',
                style: TextStyle(color: Color(0xFFFFAC93), fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 2.7)),
              const Spacer(),
              Text('FIND YOUR\nNEXT MOVE.',
                style: TextStyle(color: Colors.white,
                  fontSize: narrow ? 39 : 65, height: 1.02,
                  letterSpacing: narrow ? -1.6 : -3,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text('Fresh silhouettes. Local stores. Your style.',
                style: TextStyle(color: Colors.white.withValues(alpha: .88),
                  fontSize: narrow ? 13 : 16)),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SneakerDesign.orange, foregroundColor: Colors.white),
                onPressed: () => context.read<ShopCubit>().selectTab(2),
                icon: const Icon(Icons.north_east_rounded, size: 18),
                label: const Text('Explore Almaty stores')),
            ]),
          ),
          Positioned(top: 17, right: 17,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(10)),
              child: const Text('DEMO COLLECTION',
                style: TextStyle(color: Colors.white, fontSize: 9,
                  fontWeight: FontWeight.bold, letterSpacing: 1.3)))),
        ]),
      ),
    );
  }

  Widget _benefits(BuildContext context, bool narrow) {
    final info = [
      (Icons.storefront_outlined, '10 ALMATY STORES', 'Explore branch availability'),
      (Icons.local_shipping_outlined, 'HOME DELIVERY', 'Estimate before ordering'),
      (Icons.swap_horiz_rounded, 'FIND YOUR SIZE', 'Check stock across branches'),
    ];
    return narrow ? Column(
      children: [
        for (final item in info)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(children: [
              Icon(item.$1, color: SneakerDesign.orange, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$2, style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: .6)),
                Text(item.$3, style: Theme.of(context).textTheme.bodySmall),
              ])),
            ]),
          ),
      ],
    ) : Row(
      children: [
        for (final item in info)
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              Icon(item.$1, color: SneakerDesign.orange, size: 27),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$2, style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: .7)),
                Text(item.$3, maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall),
              ])),
            ]),
          )),
      ],
    );
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
            icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      ));
    }
    final brands = ['All',
      ...(state.products.map((p) => p['brand'] as String).toSet().toList()..sort())];
    final categories = ['All',
      ...(state.products.map((p) => p['category'] as String).toSet().toList()..sort())];
    final filtered = state.products.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final vendor = (p['brand'] as String).toLowerCase();
      final available = Map<String, dynamic>.from(p['sizes'] as Map)
        .values.any((q) => (q as num).toInt() > 0);
      return (query.trim().isEmpty || name.contains(query.toLowerCase().trim())
          || vendor.contains(query.toLowerCase().trim())) &&
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
      final w = constraints.maxWidth;
      final narrow = w < 650;
      final gap = narrow ? 10.0 : 18.0;
      final columns = w >= 1260 ? 4 : w >= 750 ? 3 : 2;
      final padding = w < 500 ? 14.0 : w < 900 ? 24.0 : 44.0;
      final tileWidth = (w - (padding * 2) - gap * (columns - 1)) / columns;
      final tileHeight = tileWidth * 1.06 + 120;
      return RefreshIndicator(
        onRefresh: () => context.read<ShopCubit>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (state.catalogLoading) const SliverToBoxAdapter(
              child: LinearProgressIndicator()),
            if (state.catalogError != null) SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.wifi_off_outlined),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Connection interrupted. Cached results may be shown.')),
                    TextButton(
                      onPressed: () => context.read<ShopCubit>().retryCatalog(),
                      child: const Text('Retry')),
                  ]),
                )),
              )),
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _hero(context, w),
                const SizedBox(height: 18),
                _benefits(context, narrow),
                const SizedBox(height: 27),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SneakerDesign.eyebrow('The collection'),
                      const SizedBox(height: 4),
                      Text('Discover sneakers.',
                        style: TextStyle(fontSize: narrow ? 26 : 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.3)),
                    ])),
                  Text('${filtered.length} STYLES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.7, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 17),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => query = value);
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Search Nike, Adidas, Air Jordan...',
                    suffixIcon: query.isEmpty ? null : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.close)),
                  ),
                ),
                const SizedBox(height: 13),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final value in brands)
                      Padding(padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(value == 'All' ? 'All brands' : value),
                          selected: brand == value,
                          onSelected: (_) => setState(() => brand = value),
                        )),
                  ]),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 9, runSpacing: 9,
                  crossAxisAlignment: WrapCrossAlignment.center, children: [
                    SizedBox(width: narrow ? 155 : 192,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('category-$category'), initialValue: category,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Category', isDense: true),
                        items: [for (final value in categories)
                          DropdownMenuItem(value: value, child: Text(value))],
                        onChanged: (v) => setState(() => category = v ?? 'All'),
                      )),
                    SizedBox(width: narrow ? 175 : 210,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('sort-$sortBy'), initialValue: sortBy, isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sort by', isDense: true),
                        items: [for (final value in const [
                          'Featured', 'Price: low to high',
                          'Price: high to low', 'Biggest discount'])
                          DropdownMenuItem(value: value, child: Text(value))],
                        onChanged: (v) => setState(() => sortBy = v ?? 'Featured'),
                      )),
                    FilterChip(
                      label: const Text('Offers'),
                      avatar: const Icon(Icons.local_offer_outlined, size: 16),
                      selected: offersOnly,
                      onSelected: (v) => setState(() => offersOnly = v)),
                    FilterChip(
                      label: const Text('Available'),
                      avatar: const Icon(Icons.check_circle_outline, size: 16),
                      selected: inStockOnly,
                      onSelected: (v) => setState(() => inStockOnly = v)),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.restart_alt_outlined, size: 17),
                      label: const Text('Reset')),
                  ]),
                const SizedBox(height: 12),
              ]),
            )),
            if (filtered.isEmpty) SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.all(40),
                child: Center(child: Column(children: [
                  const Icon(Icons.search_off_outlined, size: 46),
                  const SizedBox(height: 14),
                  const Text('No sneakers match your filters.'),
                  TextButton(onPressed: _clearFilters,
                    child: const Text('Clear filters')),
                ])))),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 40),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, crossAxisSpacing: gap, mainAxisSpacing: gap,
                  mainAxisExtent: tileHeight.clamp(255.0, 490.0),
                ),
                delegate: SliverChildBuilderDelegate((context, index) =>
                    ProductTile(product: filtered[index]), childCount: filtered.length),
              ),
            ),
          ],
        ),
      );
    });
  }
}
