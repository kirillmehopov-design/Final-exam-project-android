import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:lab10_from_lab9/models/product.dart';
import 'package:lab10_from_lab9/providers/cart_provider.dart';
import 'package:lab10_from_lab9/screens/catalog_screen.dart';
import 'package:lab10_from_lab9/screens/product_detail_screen.dart';
import 'package:lab10_from_lab9/services/product_api.dart';

const sampleJson = '''[
  {"id": 1, "title": "Sample Laptop", "price": 50,
    "description": "Fast laptop", "category": "electronics", "image": "",
    "rating": {"rate": 4.5, "count": 12}},
  {"id": 2, "title": "Sample Phone", "price": 20.5,
    "description": "Small phone", "category": "electronics", "image": "",
    "rating": {"rate": 4.2, "count": 15}}
]''';

Widget testApp(ProductApi api) => ChangeNotifierProvider(
  create: (_) => CartProvider(),
  child: MaterialApp(home: CatalogScreen(api: api)),
);

void main() {
  testWidgets('Loading then success; cart is shared between screens', (tester) async {
    final api = ProductApi(client: MockClient((_) async => http.Response(sampleJson, 200)));
    await tester.pumpWidget(testApp(api));
    expect(find.byKey(const ValueKey('loading-spinner')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Sample Laptop'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-1')));
    await tester.pumpAndSettle();
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.byTooltip('Open cart'));
    await tester.pumpAndSettle();
    expect(find.text('My Cart (1)'), findsOneWidget);
    expect(find.text('\$50.00'), findsWidgets);
    await tester.tap(find.byTooltip('Remove Sample Laptop'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Back to Catalog'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('toggle-1')), findsOneWidget);
    expect(find.text('Add to Cart'), findsNWidgets(2));
  });

  testWidgets('HTTP 500 shows Retry and the recovered catalog', (tester) async {
    var count = 0;
    final api = ProductApi(client: MockClient((_) async {
      count++;
      return count == 1 ? http.Response('{}', 500) : http.Response(sampleJson, 200);
    }));
    await tester.pumpWidget(testApp(api));
    await tester.pumpAndSettle();
    expect(find.text('Retry Connection'), findsOneWidget);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();
    expect(find.text('Sample Laptop'), findsOneWidget);
    expect(count, 2);
  });

  testWidgets('Offline network error can recover with Retry', (tester) async {
    var count = 0;
    final api = ProductApi(client: MockClient((_) async {
      count++;
      if (count == 1) throw http.ClientException('No internet');
      return http.Response(sampleJson, 200);
    }));
    await tester.pumpWidget(testApp(api));
    await tester.pumpAndSettle();
    expect(find.text('Retry Connection'), findsOneWidget);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();
    expect(find.text('Sample Laptop'), findsOneWidget);
    expect(count, 2);
  });

  testWidgets('Detail has working carousel, share sheet and shared cart', (tester) async {
    const product = Product(id: 9, title: 'Detail Item', price: 19.9,
      description: 'Detail test', category: 'electronics', imageUrl: '',
      rating: 4.8, reviewCount: 20);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MaterialApp(home: ProductDetailScreen(product: product)),
    ));
    expect(find.text('1 / 3'), findsOneWidget);
    final pageView = find.byType(PageView);
    final pageWidth = tester.getSize(pageView).width;

    await tester.timedDrag(
      pageView,
      Offset(-pageWidth * 0.7, 0),
      const Duration(milliseconds: 700),
    );

    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Share product'));
    await tester.pumpAndSettle();
    expect(find.text('narxoz://store/product/9'), findsOneWidget);
    // Close the sheet before testing the sticky cart action.
    final shareSheetContext =
    tester.element(find.text('Copy Deep Link'));

    Navigator.of(shareSheetContext).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from Cart'), findsOneWidget);
  });
}
