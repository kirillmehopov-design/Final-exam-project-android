import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final Set<int> favoriteIds;
  final List<CartItem> cartItems;
  final int cartCount;
  final ValueChanged<int> onToggleFavorite;
  final void Function(Product product, int size) onAddToCart;
  final ValueChanged<CartItem> onIncreaseCartItem;
  final ValueChanged<CartItem> onDecreaseCartItem;
  final ValueChanged<CartItem> onRemoveCartItem;

  const HomeScreen({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.cartItems,
    required this.cartCount,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onIncreaseCartItem,
    required this.onDecreaseCartItem,
    required this.onRemoveCartItem,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchText = '';

  final List<String> categories = const [
    'All',
    'Nike',
    'Adidas',
    'Jordan',
    'New Balance',
  ];

  List<Product> get filteredProducts {
    return widget.products.where((product) {
      final matchesCategory = selectedCategory == 'All' ||
          product.category == selectedCategory;

      final query = searchText.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
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

  void openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          allProducts: widget.products,
          favoriteIds: widget.favoriteIds,
          onToggleFavorite: widget.onToggleFavorite,
          onAddToCart: widget.onAddToCart,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartItems: widget.cartItems,
          onIncrease: widget.onIncreaseCartItem,
          onDecrease: widget.onDecreaseCartItem,
          onRemove: widget.onRemoveCartItem,
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
    final visibleProducts = filteredProducts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        title: const Text(
          'SneakerHub',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            onPressed: openFavorites,
            icon: const Icon(Icons.favorite_border),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Cart',
                  onPressed: openCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
                if (widget.cartCount > 0)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 1100
                ? 4
                : width >= 760
                    ? 3
                    : 2;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width >= 900 ? 32 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Find your next pair.',
                    style: TextStyle(
                      fontSize: 29,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover popular sneakers and save your favorites.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search sneakers...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryChip(
                            label: category,
                            selected: selectedCategory == category,
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Popular sneakers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '\${visibleProducts.length} items',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: visibleProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'No sneakers found.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: visibleProducts.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: width >= 760 ? 0.78 : 0.68,
                            ),
                            itemBuilder: (context, index) {
                              final product = visibleProducts[index];

                              return ProductCard(
                                product: product,
                                isFavorite:
                                    widget.favoriteIds.contains(product.id),
                                onTap: () => openProduct(product),
                                onFavoriteTap: () {
                                  widget.onToggleFavorite(product.id);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
