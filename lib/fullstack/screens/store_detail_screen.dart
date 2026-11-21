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
      appBar: AppBar(title: const Text('SneakerHub • Store')),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: limits.maxWidth < 500 ? 205 : 295,
                            child: PageView.builder(
                              itemCount: photos.length,
                              itemBuilder: (ctx, index) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(height: 16),
                          Text(store['name'] as String,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900)),
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
                          const Divider(height: 30),
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
                          Text('${visible.length} models • Same selection, branch-specific quantities'),
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
                        childAspectRatio: limits.maxWidth < 380 ? .60 : .74,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = visible[index];
                        final count = item['total_units'] as int;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openProduct(item),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: photo(item['image_url'] as String,
                                  height: 210)),
                                Padding(padding: const EdgeInsets.all(9),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'] as String, maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(item['brand'] as String, maxLines: 1,
                                        style: Theme.of(context).textTheme.bodySmall),
                                      Text(money(amount(item)),
                                        style: const TextStyle(fontWeight: FontWeight.w900)),
                                      Text(count > 0 ? '$count units available' : 'Sold out • Notify me',
                                        style: TextStyle(fontSize: 11,
                                          color: count > 0 ? Colors.green : Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: visible.length),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}
