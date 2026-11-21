import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lab10_from_lab9/models/product.dart';
import 'package:lab10_from_lab9/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const sneaker = Product(
    id: 41,
    title: 'Sneaker sample',
    price: 109.99,
    description: 'Test product',
    category: 'shoes',
    imageUrl: '',
    rating: 4.7,
    reviewCount: 12,
  );

  test('cart items survive reloading from SharedPreferences', () async {
    final cart = await CartProvider.load();
    cart.addProduct(sneaker);
    await cart.flush();

    final restored = await CartProvider.load();
    expect(restored.itemCount, 1);
    expect(restored.items.single.title, sneaker.title);
    expect(restored.totalPrice, 109.99);

    restored.removeProduct(sneaker.id);
    await restored.flush();
    final emptyCart = await CartProvider.load();
    expect(emptyCart.itemCount, 0);

    cart.dispose();
    restored.dispose();
    emptyCart.dispose();
  });

  test('corrupted saved cart does not crash startup', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CartProvider.cartKey, '{not valid json');
    final cart = await CartProvider.load();
    expect(cart.items, isEmpty);
    cart.dispose();
  });
}
