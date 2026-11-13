part of '../shop_ui.dart';

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
