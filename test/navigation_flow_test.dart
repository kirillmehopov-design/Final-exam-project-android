import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sneakerhub/fullstack/api_client.dart';
import 'package:sneakerhub/fullstack/shop_cubit.dart';
import 'package:sneakerhub/fullstack/shop_ui.dart';
import 'package:sneakerhub/providers/local_store.dart';
import 'package:sneakerhub/providers/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> buildTestApp() async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final client = MockClient((request) async {
      final path = request.url.path;
      dynamic result;
      if (path == '/products') {
        result = [
          {
            'id': 1,
            'name': 'Shoe 101',
            'brand': 'Test',
            'category': 'Lifestyle',
            'description': 'Comfortable everyday shoes',
            'image_url': '',
            'price_cents': 12500,
            'sale_price_cents': 12500,
            'discount': 0,
            'review_count': 0,
            'sizes': {'42': 10},
          },
        ];
      } else if (path == '/auth/login') {
        result = {
          'token': 'test-token',
          'user': {'email': 'customer@demo.test', 'role': 'customer'},
        };
      } else if (path == '/me') {
        result = {
          'email': 'customer@demo.test',
          'role': 'customer',
          'points': 0,
        };
      } else if (path == '/favorites') {
        result = <int>[];
      } else if (path == '/orders' || path == '/notifications' ||
          path == '/products/1/reviews') {
        result = <dynamic>[];
      } else {
        return http.Response('{"detail":"Unknown request"}', 404);
      }
      return http.Response(
        jsonEncode(result),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(store)),
        BlocProvider<ShopCubit>(
          create: (_) => ShopCubit(ApiClient(client: client), store)..initialize(),
        ),
      ],
      child: const SneakerHubFullstackApp(),
    );
  }

  for (final width in [320.0, 1100.0]) {
    testWidgets('Catalog, detail and cart work at $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 750);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Discover sneakers'), findsOneWidget);
      expect(find.text('Shoe 101'), findsOneWidget);

      await tester.tap(find.text('Shoe 101'));
      await tester.pumpAndSettle();
      expect(find.text('Product details'), findsOneWidget);
      expect(find.text('Choose size'), findsOneWidget);

      await tester.ensureVisible(find.text('Add to cart'));
      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      expect(find.text('Your cart is empty'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
