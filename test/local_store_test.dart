import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sneakerhub/models/cart_line.dart';
import 'package:sneakerhub/providers/local_store.dart';
import 'package:sneakerhub/providers/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Cart and favorites persist when LocalStore is reconstructed', () async {
    final prefs = await SharedPreferences.getInstance();
    final first = LocalStore(prefs);
    await first.saveCart([const CartLine(3, 42, 2)]);
    await first.saveFavorites({1, 3});

    final reopened = LocalStore(await SharedPreferences.getInstance());
    expect(reopened.cart.single.productId, 3);
    expect(reopened.cart.single.size, 42);
    expect(reopened.cart.single.quantity, 2);
    expect(reopened.favorites, {1, 3});
  });

  test('Theme Cubit restores persisted dark mode', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStore(prefs);
    final initial = ThemeCubit(storage);
    expect(initial.state, ThemeMode.light);
    await initial.setDarkMode(true);
    await initial.close();

    final reopened = ThemeCubit(LocalStore(await SharedPreferences.getInstance()));
    expect(reopened.state, ThemeMode.dark);
    await reopened.close();
  });
}
