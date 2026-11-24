import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/cart_badge_button.dart';
import 'cart_screen.dart';

import '../models/product.dart';
import '../widgets/product_photo_gallery.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  void _showShareSheet() {
    final link = widget.product.deepLink;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22, 8, 22,
            MediaQuery.of(sheetContext).viewInsets.bottom + 25,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Share product',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Copy the deep link to this product.',
                style: TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(link,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!mounted || !sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deep link copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Deep Link'),
                ),
              ),
            ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final color = Theme.of(context).colorScheme.primary;
    final isAdded = context.select<CartProvider, bool>(
      (cart) => cart.contains(product.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            tooltip: 'Share product',
            onPressed: _showShareSheet,
            icon: const Icon(Icons.share_outlined),
          ),
          CartBadgeButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => const CartScreen(),
            )),
          ),
          const SizedBox(width: 7),
        ],
      ),
      body: ListView(children: [
        ProductPhotoGallery(product: product),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(product.category.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w800,
                  fontSize: 11, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(product.title,
              style: const TextStyle(fontSize: 24, height: 1.25,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 11),
            Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFE8A52A), size: 22),
              const SizedBox(width: 4),
              Text(product.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('${product.reviewCount} reviews',
                style: const TextStyle(color: Colors.blueGrey)),
            ]),
            const SizedBox(height: 19),
            Text(formatPrice(product.price),
              style: TextStyle(fontSize: 29, color: color,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),
            const Text('Description',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            Text(product.description,
              style: const TextStyle(height: 1.6, color: Color(0xFF374151))),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.read<CartProvider>().toggleProduct(product),
              icon: Icon(isAdded ? Icons.check_circle : Icons.add_shopping_cart),
              label: Text(isAdded ? 'Remove from Cart' : 'Add to Cart'),
            ),
          ),
        ),
      ),
    );
  }
}
