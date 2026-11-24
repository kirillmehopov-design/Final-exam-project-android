import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'network_product_image.dart';

// Lab 9's Add/Remove toggle now sits beside real API data and network images.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final added = context.select<CartProvider, bool>(
      (cart) => cart.contains(product.id),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            SizedBox(
              width: 68,
              height: 82,
              child: Hero(
                tag: 'product_image_${product.id}',
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: NetworkProductImage(url: product.imageUrl),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(product.category, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFE8A52A),
                      size: 15),
                    Text(' ${product.rating.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11)),
                  ]),
                  Text(formatPrice(product.price),
                    style: TextStyle(fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 91,
              child: added
                  ? OutlinedButton(
                      key: ValueKey('toggle-${product.id}'),
                      onPressed: () => context.read<CartProvider>().toggleProduct(product),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Remove', style: TextStyle(fontSize: 12)),
                    )
                  : FilledButton.tonal(
                      key: ValueKey('toggle-${product.id}'),
                      onPressed: () => context.read<CartProvider>().toggleProduct(product),
                      style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Add to Cart', style: TextStyle(fontSize: 11)),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
