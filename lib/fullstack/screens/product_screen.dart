part of '../shop_ui.dart';

class ProductPage extends StatefulWidget {
  final int productId;
  final int? storeId;
  const ProductPage({super.key, required this.productId, this.storeId});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int? size;
  Future<List<Json>>? reviewFuture;
  Future<Json>? branchFuture;
  int photoIndex = 0;
  @override
  void initState() {
    super.initState();
    reviewFuture = context.read<ShopCubit>().reviews(widget.productId);
    if (widget.storeId != null) {
      branchFuture = context.read<ShopCubit>().api
        .get('/stores/${widget.storeId}/products/${widget.productId}')
        .then((value) => Map<String, dynamic>.from(value as Map));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.storeId == null) return _buildDetail(context, null);
    return FutureBuilder<Json>(
      future: branchFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(appBar: AppBar(),
          body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load size availability'),
            Text('${snapshot.error}'),
            FilledButton(onPressed: () => setState(() {
              branchFuture = context.read<ShopCubit>().api.get(
                  '/stores/${widget.storeId}/products/${widget.productId}')
                  .then((v) => Map<String, dynamic>.from(v as Map));
            }), child: const Text('Retry')),
          ])));
        if (!snapshot.hasData) return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
        return _buildDetail(context, snapshot.data);
      },
    );
  }

  Widget _buildDetail(BuildContext context, Json? branch) {
    final cubit = context.watch<ShopCubit>();
    final product = branch ?? cubit.product(widget.productId);
    if (product == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }
    final sizes = Map<String, dynamic>.from(product['sizes'] as Map);
    final inStock = sizes.entries.where((entry) => (entry.value as num) > 0)
      .map((entry) => int.parse(entry.key)).toList()..sort();
    final selectedSize = size ?? (inStock.isEmpty ? null : inStock.first);
    final available = selectedSize != null &&
      (sizes['$selectedSize'] as num? ?? 0) > 0;
    final remaining = selectedSize == null ? 0 :
      (sizes['$selectedSize'] as num? ?? 0).toInt();
    final isFavorite = cubit.state.favorites.contains(widget.productId);
    final discount = product['discount'] as int;

    Widget gallery(double width) => Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Container(
          color: SneakerDesign.imageSurface,
          height: width >= 850 ? 490 : 335,
          child: PageView.builder(
            itemCount: 3,
            onPageChanged: (index) => setState(() => photoIndex = index),
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand, children: [
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Transform.scale(
                    scale: index == 0 ? 1 : index == 1 ? 1.12 : 1.23,
                    child: photo(product['image_url'] as String, height: 400),
                  ),
                ),
                if (discount > 0) Positioned(top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: SneakerDesign.orange,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('-$discount%',
                      style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)))),
                Positioned(bottom: 14, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(9)),
                    child: Text('${index + 1} / 3',
                      style: const TextStyle(color: SneakerDesign.ink,
                        fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: photoIndex == i ? 25 : 7, height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: photoIndex == i
                ? SneakerDesign.orange : Colors.grey.shade400),
          ),
      ]),
      const SizedBox(height: 8),
      Text('Swipe for detail views',
        style: Theme.of(context).textTheme.bodySmall),
    ]);

    Widget purchase() => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        SneakerDesign.eyebrow('${product['brand']} / ${product['category']}'),
        const SizedBox(height: 10),
        Text(product['name'] as String,
          style: TextStyle(fontSize: 35, height: 1.06,
            fontWeight: FontWeight.w900, letterSpacing: -1.5)),
        const SizedBox(height: 14),
        Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(money(amount(product)),
            style: const TextStyle(fontSize: 27,
              fontWeight: FontWeight.w900)),
          if (discount > 0)
            Text(money(product['price_cents'] as int),
              style: const TextStyle(color: SneakerDesign.muted,
                fontSize: 16, decoration: TextDecoration.lineThrough)),
        ]),
        const SizedBox(height: 18),
        Text(product['description'] as String,
          style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 23),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Select your EU size',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          Text('39–45 • EU', style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final entry in sizes.entries)
            ChoiceChip(
              label: Text('${entry.key}'),
              tooltip: (entry.value as num) > 0
                ? '${entry.value} pairs available' : 'Out of stock',
              selected: selectedSize == int.parse(entry.key),
              onSelected: (_) => setState(() => size = int.parse(entry.key)),
              labelStyle: TextStyle(fontWeight: FontWeight.w800,
                color: (entry.value as num) == 0
                  ? SneakerDesign.muted : null),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(available ? Icons.check_circle_outline :
            Icons.error_outline,
            color: available ? Colors.green.shade700 : SneakerDesign.orange,
            size: 18),
          const SizedBox(width: 7),
          Expanded(child: Text(
            !available ? 'Selected size is not available at this location'
            : remaining <= 2 && widget.storeId != null
              ? 'Hurry! Only $remaining pair(s) left in this store'
              : '$remaining pair(s) available',
            style: TextStyle(fontWeight: FontWeight.w700,
              color: !available || remaining <= 2
                ? SneakerDesign.orange : null))),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 54,
          child: FilledButton.icon(
            onPressed: !available ? null : () {
              final added = cubit.addToCart(widget.productId, selectedSize,
                storeId: widget.storeId);
              if (added) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                cubit.selectTab(3);
              }
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(available ? 'Add to bag • ${money(amount(product))}'
              : 'Out of stock'),
          )),
        if (!available && selectedSize != null && widget.storeId != null) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () => cubit.subscribeBackInStock(
                widget.storeId!, widget.productId, selectedSize),
              label: Text('Notify me when EU $selectedSize returns'),
            )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _requestTransfer(context, selectedSize),
              label: const Text('Request transfer from another store'),
            )),
        ],
        if (selectedSize != null) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAvailability(context, selectedSize),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Find this size in Almaty'),
            )),
        ],
        const SizedBox(height: 22),
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 12),
        const Row(children: [
          Icon(Icons.local_shipping_outlined, size: 21,
            color: SneakerDesign.orange),
          SizedBox(width: 12),
          Expanded(child: Text('Home delivery estimate at checkout')),
        ]),
        const SizedBox(height: 13),
        const Row(children: [
          Icon(Icons.storefront_outlined, size: 21,
            color: SneakerDesign.orange),
          SizedBox(width: 12),
          Expanded(child: Text('10 Almaty demo branches • Pickup available')),
        ]),
      ],
    );

    Widget reviews() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      Divider(color: Theme.of(context).dividerColor),
      const SizedBox(height: 20),
      Row(children: [
        const Expanded(child: Text('Customer reviews',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
        TextButton(onPressed: () => _writeReview(context),
          child: const Text('Write review')),
      ]),
      const SizedBox(height: 12),
      FutureBuilder<List<Json>>(future: reviewFuture, builder: (context, snap) {
        if (snap.hasError) return Text('${snap.error}');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.isEmpty) {
          return const Text('No reviews yet. Reviews require a delivered purchase.');
        }
        return Column(children: [
          for (final review in snap.data!)
            ListTile(
              title: Text('★ ${review['rating']}  ${review['email']}'),
              subtitle: Text(review['comment'] as String)),
        ]);
      }),
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('SNEAKERHUB. / PRODUCT',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove favorite' : 'Save sneaker',
            icon: Icon(isFavorite ? Icons.favorite :
              Icons.favorite_border_rounded,
              color: isFavorite ? SneakerDesign.orange : null),
            onPressed: () => cubit.toggleFavorite(widget.productId)),
        ]),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        return ListView(
          padding: EdgeInsets.all(wide ? 32 : 16),
          children: [
            Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(children: [
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 6, child: gallery(constraints.maxWidth)),
                    const SizedBox(width: 42),
                    Expanded(flex: 5, child: purchase()),
                  ])
                else ...[
                  gallery(constraints.maxWidth),
                  const SizedBox(height: 24),
                  purchase(),
                ],
                reviews(),
              ]),
            )),
          ],
        );
      }),
    );
  }

  Future<void> _requestTransfer(BuildContext context, int requestedSize) async {
    final cubit = context.read<ShopCubit>();
    if (widget.storeId == null) return;
    List<Json> locations;
    try {
      locations = asJsonList(await cubit.api.get(
        '/products/${widget.productId}/availability?size=$requestedSize'));
      locations.removeWhere((item) => item['store_id'] == widget.storeId);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')));
      return;
    }
    if (!context.mounted) return;
    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other branches have this size right now')));
      return;
    }
    final sourceId = await showDialog<int>(context: context, builder: (dialog) =>
      AlertDialog(
        title: Text('Transfer EU $requestedSize to this store'),
        content: SizedBox(
          width: 420,
          height: 340,
          child: ListView.separated(
            itemCount: locations.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, index) {
              final branch = locations[index];
              return ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(branch['store_name'] as String),
                subtitle: Text('${branch['quantity']} pairs • ${branch['district']}'),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.pop(dialog, branch['store_id'] as int),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel')),
        ],
      ),
    );
    if (sourceId != null && context.mounted) {
      await cubit.requestStoreTransfer(
        sourceId, widget.storeId!, widget.productId, requestedSize);
    }
  }

  Future<void> _showAvailability(BuildContext context, int selectedSize) async {
    List<Json> locations;
    try {
      locations = asJsonList(await context.read<ShopCubit>().api.get(
        '/products/${widget.productId}/availability?size=$selectedSize'));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not compare stores: $error')));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (dialog) => AlertDialog(
      title: Text('EU $selectedSize • Stores with stock'),
      content: SizedBox(
        width: 420, height: 390,
        child: locations.isEmpty
          ? const Center(child: Text('No branches have this size right now.'))
          : ListView.separated(
            itemCount: locations.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final store = locations[index];
              return ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(store['store_name'] as String),
                subtitle: Text('${store['district']} • ${store['quantity']} pairs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(dialog);
                  Navigator.of(context).push<void>(MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ShopCubit>(),
                      child: StoreDetailPage(storeId: store['store_id'] as int),
                    ),
                  ));
                },
              );
            },
          ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog),
          child: const Text('Close')),
      ],
    ));
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
