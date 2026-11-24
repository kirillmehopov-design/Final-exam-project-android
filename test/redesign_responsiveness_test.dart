import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lab10_from_lab9/fullstack/api_client.dart';
import 'package:lab10_from_lab9/fullstack/shop_cubit.dart';
import 'package:lab10_from_lab9/fullstack/shop_ui.dart';
import 'package:lab10_from_lab9/providers/local_store.dart';

const _sample = [
  {
    'id': 1, 'name': 'Air Max', 'brand': 'Nike',
    'category': 'Running', 'description': 'Comfort sneakers',
    'price_cents': 7499000, 'sale_price_cents': 6749100,
    'discount': 10, 'sizes': {'40': 3, '41': 0, '42': 2},
    'image_url': 'https://invalid.test/sample.jpg',
  },
];

Future<ShopCubit> _createShop() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(client: MockClient((request) async {
    if (request.url.path == '/products') {
      return http.Response(jsonEncode(_sample), 200);
    }
    return http.Response(jsonEncode(<String, dynamic>{}), 200);
  }));
  final cubit = ShopCubit(api, LocalStore(prefs));
  await cubit.initialize();
  return cubit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [320.0, 1440.0]) {
    testWidgets('retail catalog does not overflow at ${width.toInt()}px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final cubit = await _createShop();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider.value(value: cubit,
            child: const MaterialApp(
              home: Scaffold(body: CatalogPage()),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Find your lane.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('copyright footer is functional at ${width.toInt()}px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 850);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = await _createShop();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider.value(value: cubit,
            child: const MaterialApp(home: Scaffold(
              body: SingleChildScrollView(child: SneakerSiteFooter()),
            )),
          ),
        );
        expect(find.text('© SneakerHub 2026. All rights reserved.'),
          findsOneWidget);
        await tester.ensureVisible(find.text('Almaty stores'));
        await tester.tap(find.text('Almaty stores'));
        await tester.pump();
        expect(cubit.state.tab, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
