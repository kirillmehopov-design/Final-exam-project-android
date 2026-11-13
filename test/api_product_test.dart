import 'package:flutter_test/flutter_test.dart';
import 'package:sneakerhub/models/api_product.dart';

void main() {
  test('Product.fromJson handles int and double prices safely', () {
    final source = {
      'id': 8,
      'name': 'Demo sneaker',
      'brand': 'Demo',
      'price': 120,
      'image_url': 'https://example.com/p.png',
    };
    final product = ApiProduct.fromJson(source);
    expect(product.price, 120.0);
    final doubleProduct = ApiProduct.fromJson({
      ...source,
      'price': 99.99,
    });
    expect(doubleProduct.price, 99.99);
  });

  test('Backend price in cents is converted into a double price', () {
    final source = {
      'id': 2,
      'name': 'Running shoe',
      'brand': 'Brand',
      'image_url': 'https://example.com/p.png',
      'sale_price_cents': 12999,
    };
    final parsed = ApiProduct.fromJson(ApiProduct.normalize(source));
    expect(parsed.price, 129.99);
  });
}
