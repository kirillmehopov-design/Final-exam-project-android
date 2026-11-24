import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab10_from_lab9/services/product_api.dart';

const sampleJson = '''[
  {
    "id": 1, "title": "Camera", "price": 50,
    "description": "A test camera", "category": "electronics",
    "image": "", "rating": {"rate": 4.5, "count": 9}
  }
]''';

void main() {
  test('200 OK decodes JSON and converts numeric price', () async {
    final api = ProductApi(client: MockClient((request) async {
      expect(request.url.toString(), 'https://fakestoreapi.com/products');
      return http.Response(sampleJson, 200);
    }));
    final products = await api.fetchProducts();
    expect(products.length, 1);
    expect(products.single.price, 50.0);
    expect(products.single.rating, 4.5);
  });

  for (final code in [404, 500]) {
    test('HTTP $code becomes a readable API exception', () async {
      final api = ProductApi(client: MockClient(
        (_) async => http.Response('{}', code)));
      await expectLater(api.fetchProducts(), throwsA(
        isA<ProductApiException>().having((e) => e.statusCode,
          'statusCode', code),
      ));
    });
  }

  test('unexpected JSON shape produces an API exception', () async {
    final api = ProductApi(client: MockClient(
      (_) async => http.Response('{"error":"not an array"}', 200)));
    await expectLater(api.fetchProducts(), throwsA(isA<ProductApiException>()));
  });

  test('10-second timeout path, using a small test timeout', () async {
    final api = ProductApi(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response(sampleJson, 200);
      }),
      timeout: const Duration(milliseconds: 2),
    );
    await expectLater(api.fetchProducts(), throwsA(
      isA<ProductApiException>().having(
        (e) => e.message, 'message', contains('timed out')),
    ));
  });
}
