import 'package:flutter/foundation.dart';
import '../models/product.dart';

// One shared cart for every screen.
class CartProvider extends ChangeNotifier {
  final List<Product> _items = [];

  // The UI can read the cart but cannot modify the internal list directly.
  List<Product> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalPrice => _items.fold(0.0, (sum, p) => sum + p.price);
  bool contains(int id) => _items.any((p) => p.id == id);

  void addProduct(Product product) {
    if (contains(product.id)) return; // Each product is added at most once.
    _items.add(product);
    notifyListeners(); // Rebuild UI that listens to this cart.
  }

  void removeProduct(int productId) {
    final previousLength = _items.length;
    _items.removeWhere((p) => p.id == productId);
    if (_items.length != previousLength) notifyListeners();
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
  }
}
