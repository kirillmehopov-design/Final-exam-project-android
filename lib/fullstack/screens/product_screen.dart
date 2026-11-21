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
    if (product == null) return const Scaffold(body: Center(child: Text('Product not found')));
    final sizes = Map<String, dynamic>.from(product['sizes'] as Map);
    final inStock = sizes.entries.where((e) => (e.value as int) > 0)
        .map((e) => int.parse(e.key)).toList()..sort();
    final selectedSize = size ?? (inStock.isEmpty ? null : inStock.first);
    final available = selectedSize != null && (sizes['$selectedSize'] as int? ?? 0) > 0;
    final isFavorite = cubit.state.favorites.contains(widget.productId);
    return Scaffold(
      appBar: AppBar(title: const Text('Product details'), actions: [
        IconButton(icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: () => cubit.toggleFavorite(widget.productId)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: 290, child: PageView.builder(
              itemCount: 3,
              onPageChanged: (value) => setState(() => photoIndex = value),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  Transform.scale(
                    scale: index == 0 ? 1.0 : index == 1 ? 1.16 : 1.34,
                    child: photo(product['image_url'] as String, height: 290)),
                  Positioned(bottom: 8, right: 10, child: Chip(
                    label: Text('${index + 1} / 3'))),
                ]),
              ),
            )),
            const SizedBox(height: 8),
            Text('Swipe photos: full view • detail • close-up',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
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
            Wrap(spacing: 8, runSpacing: 5, children: [
              for (final item in sizes.entries)
                ChoiceChip(
                  label: Text('EU ${item.key} (${item.value})'),
                  selected: selectedSize == int.parse(item.key),
                  onSelected: (_) => setState(() => size = int.parse(item.key)),
                ),
            ]),
            if (selectedSize != null && !available)
              Padding(padding: const EdgeInsets.only(top: 12), child:
                OutlinedButton.icon(
                  onPressed: widget.storeId == null ? null : () async {
                    await cubit.subscribeBackInStock(widget.storeId!,
                        widget.productId, selectedSize);
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text('Notify when EU $selectedSize is back'),
                )),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: !available ? null : () {
              final added = cubit.addToCart(widget.productId, selectedSize,
                storeId: widget.storeId);
              if (added) {
                Navigator.pop(context);
                cubit.selectTab(3);
              }
            }, icon: const Icon(Icons.add_shopping_cart),
              label: Text(available ? 'Add to cart' : 'Out of stock')),
            if (selectedSize != null && widget.storeId != null)
              Padding(padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _showAvailability(context, selectedSize),
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: const Text('Check this size at other stores'),
                )),
            if (widget.storeId != null)
              Padding(padding: const EdgeInsets.only(top: 6),
                child: Text('Branch #${widget.storeId} • Availability and sizes are per store.',
                  style: Theme.of(context).textTheme.bodySmall)),
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
