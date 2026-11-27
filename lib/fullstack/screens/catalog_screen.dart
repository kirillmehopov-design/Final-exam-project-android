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
  int? selectedSize;
  String priceRange = 'Any price';
  final GlobalKey _collectionKey = GlobalKey();
  Timer? _searchDebounce;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
    query = '';
    brand = 'All';
    category = 'All';
    sortBy = 'Featured';
    offersOnly = false;
    inStockOnly = false;
    selectedSize = null;
    priceRange = 'Any price';
    _searchController.clear();
  });

  final _searchController = TextEditingController();
  void _scrollToCollection() {
    final target = _collectionKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic, alignment: .03);
    }
  }

  void _chooseEdit(String value) {
    setState(() {
      category = value;
      brand = 'All';
      offersOnly = false;
      inStockOnly = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToCollection();
    });
  }

  int get activeFilters => (brand == 'All' ? 0 : 1) +
    (selectedSize == null ? 0 : 1) + (priceRange == 'Any price' ? 0 : 1) +
    (offersOnly ? 1 : 0) + (inStockOnly ? 1 : 0);

  Widget _activeFilterChip(String text, VoidCallback onRemove) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: InputChip(
      label: Text(text),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
    ),
  );

  Future<void> _openFilters(BuildContext context, double width,
      List<String> brands, List<int> sizes) async {
    Widget content(BuildContext dialog, StateSetter redraw) {
      void change(VoidCallback fn) {
        setState(fn);
        redraw(() {});
      }
      Widget heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(), style: const TextStyle(
          fontWeight: FontWeight.w900, letterSpacing: 1.3, fontSize: 12)),
      );
      return SafeArea(top: false, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(children: [
              const Expanded(child: Text('Refine your selection',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
              IconButton(
                tooltip: 'Close filters',
                onPressed: () => Navigator.pop(dialog),
                icon: const Icon(Icons.close)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
            heading('Brand'),
            Wrap(spacing: 7, runSpacing: 6, children: [
              for (final item in brands)
                ChoiceChip(label: Text(item == 'All' ? 'All brands' : item),
                  selected: brand == item,
                  onSelected: (_) => change(() => brand = item)),
            ]),
            const SizedBox(height: 24),
            heading('EU size'),
            Wrap(spacing: 8, runSpacing: 6, children: [
              ChoiceChip(label: const Text('Any'),
                selected: selectedSize == null,
                onSelected: (_) => change(() => selectedSize = null)),
              for (final item in sizes)
                ChoiceChip(label: Text('$item'),
                  selected: selectedSize == item,
                  onSelected: (_) => change(() => selectedSize = item)),
            ]),
            const SizedBox(height: 24),
            heading('Price'),
            DropdownButtonFormField<String>(
              key: ValueKey('price-$priceRange'),
              initialValue: priceRange,
              decoration: const InputDecoration(labelText: 'Price range'),
              items: [
                for (final item in const ['Any price', 'Under 60 000 ₸',
                  'Under 80 000 ₸', '80 000 ₸+'])
                  DropdownMenuItem(value: item, child: Text(item)),
              ],
              onChanged: (v) => change(
                () => priceRange = v ?? 'Any price'),
            ),
            const SizedBox(height: 20),
            heading('Availability'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: offersOnly,
              title: const Text('On sale'),
              onChanged: (v) => change(() => offersOnly = v)),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: inStockOnly,
              title: const Text('In stock'),
              onChanged: (v) => change(() => inStockOnly = v)),
          ])),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(children: [
              TextButton(onPressed: () {
                _clearFilters();
                redraw(() {});
              }, child: const Text('Reset all')),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Show products'))),
            ])),
        ]));
    }
    if (width < 720) {
      await showModalBottomSheet<void>(
        context: context, isScrollControlled: true, useSafeArea: true,
        showDragHandle: true,
        builder: (dialog) => FractionallySizedBox(
          heightFactor: .85,
          child: StatefulBuilder(builder: content)),
      );
    } else {
      await showGeneralDialog<void>(
        context: context, barrierDismissible: true,
        barrierLabel: 'Close filters',
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (dialog, _, __) => Align(
          alignment: Alignment.centerRight,
          child: Material(color: Theme.of(context).colorScheme.surface,
            child: SizedBox(width: 420, height: double.infinity,
              child: StatefulBuilder(builder: content)))),
        transitionBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0),
            end: Offset.zero).animate(animation),
          child: child),
      );
    }
  }

  Widget _hero(BuildContext context, double width) {
    final small = width < 720;
    final desktop = width >= 720;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: SneakerDesign.lime)),
          child: const Text('ALMATY / SNEAKER CULTURE / 2026',
            style: TextStyle(color: SneakerDesign.lime,
              fontSize: 10, fontWeight: FontWeight.w800,
              letterSpacing: 1.5)),
        ),
        const Spacer(),
        Text('STEP INTO\nSOMETHING\nNEW.',
          style: TextStyle(color: Colors.white,
            fontSize: small ? 39 : 62, height: .95,
            fontWeight: FontWeight.w900, letterSpacing: small ? -2 : -3.5)),
        const SizedBox(height: 16),
        Text('Your sneakers, your city. Find iconic pairs, check your size\nand shop your nearest SneakerHub concept store.',
          style: const TextStyle(color: Colors.white70,
            fontSize: 13, height: 1.6),
          maxLines: small ? 3 : 4),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: SneakerDesign.lime,
              foregroundColor: SneakerDesign.ink),
            onPressed: _scrollToCollection,
            icon: const Icon(Icons.arrow_downward, size: 18),
            label: const Text('SHOP THE COLLECTION')),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54)),
            onPressed: () => context.read<ShopCubit>().selectTab(2),
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('10 STORES')),
        ]),
        if (desktop) const SizedBox(height: 22),
      ],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: SneakerDesign.graphite,
        height: small ? 545 : 510,
        child: Stack(children: [
          if (small)
            Positioned.fill(child: Image.network(
              'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1400&q=85',
              fit: BoxFit.cover, alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF383D39)))),
          if (small)
            Positioned.fill(child: DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: .36),
                  Colors.black.withValues(alpha: .92)])))),
          if (small)
            Positioned.fill(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 25, 22, 28), child: text)),
          if (!small)
            Row(children: [
              Expanded(flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(50, 38, 0, 34),
                  child: text)),
              Expanded(flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Stack(fit: StackFit.expand, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1500&q=85',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF46443F)))),
                    const Positioned(top: 20, left: 20,
                      child: Text('THE CURATED EDIT.   /   001',
                        style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w900,
                          letterSpacing: 2))),
                    const Positioned(bottom: 17, right: 18,
                      child: Text('MOVE DIFFERENT ↗',
                        style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w900,
                          letterSpacing: 2))),
                  ]))),
            ]),
        ]),
      ),
    );
  }

  Widget _shopEdits(BuildContext context, bool narrow) {
    final edits = <(String, String, String, String)>[
      ('Lifestyle', 'EVERYDAY ICONS', 'Made for every move.',
        'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=700&q=85'),
      ('Running', 'RUN CLUB', 'Comfort, from day one.',
        'https://images.unsplash.com/photo-1608231387042-66d1773070a5?auto=format&fit=crop&w=700&q=85'),
      ('Streetwear', 'STREET ESSENTIALS', 'Own the pavement.',
        'https://images.unsplash.com/photo-1600269452121-4f2416e55c28?auto=format&fit=crop&w=700&q=85'),
    ];
    Widget card((String, String, String, String) item) => InkWell(
      onTap: () => _chooseEdit(item.$1),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: narrow ? 190 : 260,
        decoration: BoxDecoration(color: SneakerDesign.imageSurface,
          borderRadius: BorderRadius.circular(5)),
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: BorderRadius.circular(5),
            child: Image.network(item.$4, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF737B71)))),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: .85)]))),
          Positioned(bottom: 20, left: 20, right: 14, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.$2, style: const TextStyle(
                color: Colors.white, fontSize: 20, letterSpacing: -.7,
                fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(item.$3, style:
                  const TextStyle(color: Colors.white70, fontSize: 12))),
                const Icon(Icons.arrow_outward, color: SneakerDesign.lime, size: 21),
              ]),
            ])),
        ]),
      ),
    );
    if (narrow) return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: edits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, i) => SizedBox(width: 250, child: card(edits[i])),
      ),
    );
    return Row(children: [
      for (var i = 0; i < edits.length; i++) ...[
        if (i > 0) const SizedBox(width: 15),
        Expanded(child: card(edits[i])),
      ],
    ]);
  }

  Widget _featured(BuildContext context, List<Json> products, bool narrow) {
    final items = products.take(5).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SneakerDesign.eyebrow('Selected for you'),
          const SizedBox(height: 5),
          Text('On our radar.', style: TextStyle(fontWeight: FontWeight.w900,
            fontSize: narrow ? 26 : 36, letterSpacing: -1.2)),
        ])),
        TextButton.icon(onPressed: _scrollToCollection,
          icon: const Icon(Icons.arrow_outward, size: 18),
          label: const Text('View all')),
      ]),
      const SizedBox(height: 14),
      SizedBox(height: narrow ? 297 : 346,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (ctx, index) => SizedBox(
            width: narrow ? 204 : 250,
            child: ProductTile(product: items[index])),
        )),
    ]);
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
              Icon(item.$1, color: SneakerDesign.ink, size: 22),
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
              Icon(item.$1, color: SneakerDesign.ink, size: 27),
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
        (!inStockOnly || available) &&
        (selectedSize == null || (Map<String,dynamic>.from(p['sizes'] as Map)
          ['$selectedSize'] as num? ?? 0) > 0) &&
        (priceRange == 'Any price' ||
          (priceRange == 'Under 60 000 ₸' && amount(p) < 6000000) ||
          (priceRange == 'Under 80 000 ₸' && amount(p) < 8000000) ||
          (priceRange == '80 000 ₸+' && amount(p) >= 8000000));
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
          controller: _scroll,
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
                const SizedBox(height: 28),
                SneakerDesign.eyebrow('Explore by attitude'),
                const SizedBox(height: 7),
                Text('Find your lane.',
                  style: TextStyle(fontSize: narrow ? 27 : 36,
                    fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                const SizedBox(height: 15),
                _shopEdits(context, narrow),
                const SizedBox(height: 34),
                _featured(context, state.products, narrow),
                const SizedBox(height: 15),
                _benefits(context, narrow),
                const SizedBox(height: 27),
                Container(
                  key: _collectionKey,
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 300), () {
                          if (mounted) setState(() => query = value);
                        });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: narrow ? 'Search sneakers...' :
                        'Search Nike, Adidas, Air Jordan...',
                      suffixIcon: query.isEmpty ? null : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _searchController.clear();
                          setState(() => query = '');
                        }),
                    ),
                  )),
                  const SizedBox(width: 9),
                  OutlinedButton.icon(
                    key: const ValueKey('catalog-open-filters'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(narrow ? 50 : 125, 56),
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 12 : 16),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      final sizes = state.products
                        .expand((p) => Map<String,dynamic>.from(
                          p['sizes'] as Map).keys)
                        .map(int.tryParse).whereType<int>().toSet().toList()
                        ..sort();
                      _openFilters(context, w, brands, sizes);
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: narrow ? const SizedBox.shrink()
                      : Text('Filters${activeFilters == 0 ? '' : ' ($activeFilters)'}'),
                  ),
                ]),
                const SizedBox(height: 11),
                Row(children: [
                  Expanded(child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final value in categories)
                        Padding(padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            key: ValueKey('category-$value'),
                            label: Text(value == 'All' ? 'All shoes' : value),
                            selected: category == value,
                            onSelected: (_) => setState(() => category = value),
                          )),
                    ]),
                  )),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    key: const ValueKey('catalog-sort'),
                    tooltip: 'Sort products',
                    initialValue: sortBy,
                    onSelected: (value) => setState(() => sortBy = value),
                    itemBuilder: (context) => [
                      for (final value in const [
                        'Featured', 'Price: low to high',
                        'Price: high to low', 'Biggest discount'])
                        PopupMenuItem(value: value, child: Text(value)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 10),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.sort, size: 21),
                        if (!narrow) ...[
                          const SizedBox(width: 6),
                          const Text('Sort', style: TextStyle(
                            fontWeight: FontWeight.w700)),
                        ],
                      ]),
                    ),
                  ),
                ]),
                if (activeFilters > 0 || query.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(height: 41, child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (brand != 'All')
                        _activeFilterChip(brand,
                          () => setState(() => brand = 'All')),
                      if (selectedSize != null)
                        _activeFilterChip('EU $selectedSize',
                          () => setState(() => selectedSize = null)),
                      if (priceRange != 'Any price')
                        _activeFilterChip(priceRange,
                          () => setState(() => priceRange = 'Any price')),
                      if (offersOnly)
                        _activeFilterChip('Offers',
                          () => setState(() => offersOnly = false)),
                      if (inStockOnly)
                        _activeFilterChip('In stock',
                          () => setState(() => inStockOnly = false)),
                      if (query.isNotEmpty)
                        _activeFilterChip('Search: $query', () {
                          _searchDebounce?.cancel();
                          _searchController.clear();
                          setState(() => query = '');
                        }),
                      TextButton(onPressed: _clearFilters,
                        child: const Text('Clear all')),
                    ],
                  )),
                ],
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
            SliverToBoxAdapter(
              child: SneakerSiteFooter(onBackToTop: () {
                if (_scroll.hasClients) {
                  _scroll.animateTo(0, duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic);
                }
              }),
            ),
          ],
        ),
      );
    });
  }
}
