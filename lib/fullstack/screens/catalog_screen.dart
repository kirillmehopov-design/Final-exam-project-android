part of '../shop_ui.dart';

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
