import 'package:flutter/material.dart';

import 'data/products.dart';
import 'models/cart_item.dart';
import 'models/product.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SneakerHubApp());
}

class SneakerHubApp extends StatefulWidget {
  const SneakerHubApp({super.key});

  @override
  State<SneakerHubApp> createState() => _SneakerHubAppState();
}

class _SneakerHubAppState extends State<SneakerHubApp> {
  final Set<int> favoriteIds = {};
  final List<CartItem> cartItems = [];

  int get cartCount {
    return cartItems.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  void toggleFavorite(int productId) {
    setState(() {
      if (favoriteIds.contains(productId)) {
        favoriteIds.remove(productId);
      } else {
        favoriteIds.add(productId);
      }
    });
  }

  void addToCart(Product product, int size) {
    setState(() {
      final index = cartItems.indexWhere(
        (item) => item.product.id == product.id && item.size == size,
      );

      if (index == -1) {
        cartItems.add(
          CartItem(
            product: product,
            size: size,
          ),
        );
      } else {
        cartItems[index].quantity++;
      }
    });
  }

  void increaseCartItem(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void decreaseCartItem(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cartItems.remove(item);
      }
    });
  }

  void removeCartItem(CartItem item) {
    setState(() {
      cartItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SneakerHub',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111111),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      home: HomeScreen(
        products: products,
        favoriteIds: favoriteIds,
        cartItems: cartItems,
        cartCount: cartCount,
        onToggleFavorite: toggleFavorite,
        onAddToCart: addToCart,
        onIncreaseCartItem: increaseCartItem,
        onDecreaseCartItem: decreaseCartItem,
        onRemoveCartItem: removeCartItem,
      ),
    );
  }
}
