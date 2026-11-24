part of '../shop_ui.dart';

/// A branch owns its own per-size quantities, fetched from the REST API.
class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({super.key, required this.storeId});
  final int storeId;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late Future<(Json, List<Json>)> _future;
  String filter = '';
  bool availableOnly = false;
  int galleryPage = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final api = context.read<ShopCubit>().api;
    _future = Future.wait<dynamic>([
      api.get('/stores/${widget.storeId}'),
      api.get('/stores/${widget.storeId}/products'),
    ]).then((results) => (
      Map<String, dynamic>.from(results[0] as Map),
      asJsonList(results[1])
    ));
  }

  void _openProduct(Json item) {
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<ShopCubit>(),
        child: ProductPage(
          productId: item['id'] as int,
          storeId: widget.storeId,
        ),
      ),
    )).then((_) {
      if (mounted) setState(_reload);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SNEAKERHUB. / STORE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -.4)),
        actions: [
          IconButton(
            tooltip: 'Open cart',
            onPressed: () {
              context.read<ShopCubit>().selectTab(3);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: FutureBuilder<(Json, List<Json>)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load this store.'),
                Text('${snapshot.error}'),
                FilledButton(onPressed: () => setState(_reload),
                  child: const Text('Retry')),
              ],
            ));
            return const Center(child: CircularProgressIndicator());
          }
          final store = snapshot.data!.$1;
          final all = snapshot.data!.$2;
          final visible = all.where((p) {
            final name = ('${p['brand']} ${p['name']}').toLowerCase();
            return name.contains(filter.toLowerCase()) &&
                (!availableOnly || (p['total_units'] as int) > 0);
          }).toList();
          final photos = (store['photos'] as List).cast<String>();
          return LayoutBuilder(builder: (context, limits) {
            final columns = limits.maxWidth >= 900 ? 4 : limits.maxWidth >= 600 ? 3 : 2;
            return RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                await _future;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.all(limits.maxWidth < 500 ? 14 : 28),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: limits.maxWidth < 500 ? 205 : 295,
                            child: PageView.builder(
                              itemCount: photos.length,
                              onPageChanged: (index) => setState(() => galleryPage = index),
                              itemBuilder: (ctx, index) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(photos[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Theme.of(context).colorScheme.surfaceContainer,
                                      child: const Icon(Icons.storefront, size: 70)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            for (var i = 0; i < photos.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                height: 5, width: i == galleryPage ? 25 : 8,
                                decoration: BoxDecoration(
                                  color: i == galleryPage
                                    ? SneakerDesign.ink : SneakerDesign.line,
                                  borderRadius: BorderRadius.circular(3)),
                              ),
                          ]),
                          const SizedBox(height: 28),
                          SneakerDesign.eyebrow('Almaty / Curated spaces'),
                          const SizedBox(height: 7),
                          Text(store['name'] as String,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: limits.maxWidth < 500 ? 28 : 40,
                              letterSpacing: -1.5, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(store['description'] as String),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 4, children: [
                            Chip(avatar: const Icon(Icons.location_on_outlined, size: 17),
                              label: Text(store['district'] as String)),
                            Chip(avatar: const Icon(Icons.access_time, size: 17),
                              label: Text(store['hours'] as String)),
                            Chip(avatar: const Icon(Icons.inventory_2_outlined, size: 17),
                              label: Text('${store['available_models']} models in stock')),
                          ]),
                          const SizedBox(height: 8),
                          Text(store['address_hint'] as String),
                          const Text('DEMO STORE • Photos and opening hours are illustrative.',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const Divider(height: 40),
                          SneakerDesign.eyebrow('This branch / live demo stock'),
                          const SizedBox(height: 5),
                          Text('Shop this store',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
                              hintText: 'Search models in this store',
                              border: OutlineInputBorder()),
                            onChanged: (value) => setState(() => filter = value),
                          ),
                          SwitchListTile.adaptive(
                            title: const Text('Only available models'),
                            value: availableOnly,
                            onChanged: (v) => setState(() => availableOnly = v)),
                          Text('${visible.length} models • Different quantities by size, per branch',
                            style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ))),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns, crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: ((limits.maxWidth - 24 - (columns - 1) * 10) / columns * 1.05 + 128).clamp(260, 480).toDouble(),
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) =>
                        ProductTile(
                          product: visible[index],
                          storeId: widget.storeId,
                          onOpen: () => _openProduct(visible[index]),
                        ), childCount: visible.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SneakerSiteFooter()),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}
