import 'package:flutter_test/flutter_test.dart';
import 'package:lab10_from_lab9/models/product.dart';
import 'package:lab10_from_lab9/providers/cart_provider.dart';

const sampleProducts = [
  Product(id: 1, title: 'Laptop', price: 350, description: 'Test',
    category: 'electronics', imageUrl: '', rating: 4.5, reviewCount: 12),
  Product(id: 2, title: 'Phone', price: 220, description: 'Test',
    category: 'electronics', imageUrl: '', rating: 4.2, reviewCount: 10),
];

void main() {
  group('CartProvider', () {
    test('starts empty and calculates total', () {
      final cart = CartProvider();
      expect(cart.itemCount, 0);
      expect(cart.totalPrice, 0);
      cart.addProduct(sampleProducts[0]);
      cart.addProduct(sampleProducts[1]);
      expect(cart.itemCount, 2);
      expect(cart.totalPrice, 570);
    });

    test('toggle adds/removes without duplicates', () {
      final cart = CartProvider();
      cart.addProduct(sampleProducts[0]);
      cart.addProduct(sampleProducts[0]);
      expect(cart.itemCount, 1);
      cart.toggleProduct(sampleProducts[0]);
      expect(cart.itemCount, 0);
      cart.toggleProduct(sampleProducts[0]);
      expect(cart.itemCount, 1);
    });

    test('remove one and clear all', () {
      final cart = CartProvider();
      cart.addProduct(sampleProducts[0]);
      cart.addProduct(sampleProducts[1]);
      cart.removeProduct(1);
      expect(cart.itemCount, 1);
      expect(cart.totalPrice, 220);
      cart.clearAll();
      expect(cart.itemCount, 0);
      expect(cart.totalPrice, 0);
    });
  });
}
