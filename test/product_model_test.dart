import 'package:flutter_test/flutter_test.dart';
import 'package:lab10_from_lab9/models/product.dart';

void main() {
  test('fromJson handles integer price, integer rating and nested count', () {
    final product = Product.fromJson({
      'id': 3,
      'title': 'Laptop',
      'price': 120,
      'description': 'A test laptop',
      'category': 'electronics',
      'image': 'https://example.com/laptop.png',
      'rating': {'rate': 4, 'count': 12},
    });
    expect(product.id, 3);
    expect(product.price, 120.0);
    expect(product.rating, 4.0);
    expect(product.reviewCount, 12);
    expect(product.galleryUrls.length, 3);
    expect(product.galleryUrls.toSet().length, 1);
    expect(product.deepLink, 'narxoz://store/product/3');
  });

  test('fromJson accepts floating numbers and optional image gallery', () {
    final product = Product.fromJson({
      'id': 7.0,
      'title': 'Camera',
      'price': 15.75,
      'description': 'A camera',
      'category': 'cameras',
      'image': 'https://example.com/a.jpg',
      'images': [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
        'https://example.com/c.jpg',
      ],
      'rating': {'rate': 4.8, 'count': 14},
    });
    expect(product.id, 7);
    expect(product.price, 15.75);
    expect(product.galleryUrls.toSet().length, 3);
  });

  test('fromJson falls back safely for null or wrong-typed data', () {
    final product = Product.fromJson({
      'id': null,
      'title': null,
      'price': 'bad-number',
      'description': null,
      'category': null,
      'image': null,
      'rating': null,
    });
    expect(product.id, 0);
    expect(product.title, 'Untitled product');
    expect(product.price, 0.0);
    expect(product.description, 'No description available.');
    expect(product.rating, 0.0);
    expect(product.reviewCount, 0);
    expect(product.galleryUrls.length, 3);
  });
}
