import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../widgets/network_product_image.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) => Scaffold(
        appBar: AppBar(
          title: Text('My Cart (${cart.itemCount})'),
          actions: [
            TextButton(
              onPressed: cart.itemCount == 0 ? null : cart.clearAll,
              child: const Text('Clear All'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_shopping_cart_outlined,
                    size: 70, color: Colors.blueGrey),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Catalog'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.itemCount,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = cart.items[index];
                return ListTile(
                  key: ValueKey('cart-item-${product.id}'),
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: SizedBox(
                    width: 48, height: 48,
                    child: NetworkProductImage(url: product.imageUrl),
                  ),
                  title: Text(product.title, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatPrice(product.price)),
                  trailing: IconButton(
                    tooltip: 'Remove ${product.title}',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => context.read<CartProvider>().removeProduct(product.id),
                  ),
                );
              },
            ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Price:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(formatPrice(cart.totalPrice),
                  key: const ValueKey('cart-total-price'),
                  style: const TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 20, color: Color(0xFF315BD8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
