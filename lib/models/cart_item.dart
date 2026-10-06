import 'product.dart';

class CartItem {
  final Product product;
  final int size;
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}
