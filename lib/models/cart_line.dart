class CartLine {
  final int productId;
  final int size;
  final int quantity;

  const CartLine(this.productId, this.size, this.quantity);

  CartLine withQuantity(int quantity) =>
      CartLine(productId, size, quantity);
}
