import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Product> allProducts;
  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final void Function(Product product, int size) onAddToCart;

  const FavoritesScreen({
    super.key,
    required this.allProducts,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Product> get favoriteProducts {
    return widget.allProducts
        .where((product) => widget.favoriteIds.contains(product.id))
        .toList();
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          initialFavorite: widget.favoriteIds.contains(product.id),
          onToggleFavorite: () => widget.onToggleFavorite(product.id),
          onAddToCart: widget.onAddToCart,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = favoriteProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                      color: Colors.black26,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap the heart icon on any sneaker.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          final width = constraints.maxWidth;
          final count = width >= 1100
              ? 4
              : width >= 760
                  ? 3
                  : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: width >= 760 ? 0.78 : 0.68,
            ),
            itemBuilder: (context, index) {
              final product = items[index];

              return ProductCard(
                product: product,
                isFavorite: true,
                onTap: () => openProduct(product),
                onFavoriteTap: () {
                  widget.onToggleFavorite(product.id);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}
