import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// A single shared cart, restored before runApp() and persisted on changes.
class CartProvider extends ChangeNotifier {
  CartProvider({SharedPreferences? preferences}) : _preferences = preferences;

  static const String cartKey = 'sneakerhub_cart_json';
  final SharedPreferences? _preferences;
  final List<Product> _items = [];
  Future<void> _writeQueue = Future<void>.value();

  /// Use this factory in main(); the normal constructor remains useful in tests.
  static Future<CartProvider> load() async {
    final preferences = await SharedPreferences.getInstance();
    final cart = CartProvider(preferences: preferences);
    final encoded = preferences.getString(cartKey);
    if (encoded == null || encoded.isEmpty) return cart;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is List) {
        final seen = <int>{};
        for (final item in decoded) {
          if (item is! Map) continue;
          final product = Product.fromJson(Map<String, dynamic>.from(item));
          if (product.id > 0 && seen.add(product.id)) {
            cart._items.add(product);
          }
        }
      }
    } catch (_) {
      // Damaged local data must never crash a cold start.
    }
    return cart;
  }

  List<Product> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalPrice => _items.fold(0.0, (sum, p) => sum + p.price);
  bool contains(int id) => _items.any((p) => p.id == id);

  void addProduct(Product product) {
    if (contains(product.id)) return;
    _items.add(product);
    notifyListeners();
    _save();
  }

  void removeProduct(int productId) {
    final before = _items.length;
    _items.removeWhere((p) => p.id == productId);
    if (_items.length == before) return;
    notifyListeners();
    _save();
  }

  void toggleProduct(Product product) {
    if (contains(product.id)) {
      removeProduct(product.id);
    } else {
      addProduct(product);
    }
  }

  void clearAll() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    _save();
  }

  /// Serialized write order prevents an old cart snapshot from overwriting
  /// a newer snapshot when the user changes multiple products quickly.
  void _save() {
    final prefs = _preferences;
    if (prefs == null) return;
    final snapshot = jsonEncode(_items.map((p) => p.toJson()).toList());
    _writeQueue = _writeQueue.then((_) async {
      final saved = await prefs.setString(cartKey, snapshot);
      if (!saved) throw StateError('Could not save cart');
    }).catchError((Object error, StackTrace stack) {
      debugPrint('SneakerHub cart persistence failed: $error');
    });
  }

  /// Allow tests and callers to wait for pending local writes.
  Future<void> flush() => _writeQueue;
}
