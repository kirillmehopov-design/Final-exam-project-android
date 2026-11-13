import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../fullstack/shop_cubit.dart';

class LocalStore {
  static const _themeKey = 'sneakerhub.theme.dark';
  static const _cartKey = 'sneakerhub.cart.v1';
  static const _favoritesKey = 'sneakerhub.favorites.v1';

  final SharedPreferences prefs;
  LocalStore(this.prefs);

  bool get darkMode => prefs.getBool(_themeKey) ?? false;

  Future<void> saveDarkMode(bool enabled) =>
      prefs.setBool(_themeKey, enabled);

  List<CartLine> get cart {
    try {
      final value = jsonDecode(prefs.getString(_cartKey) ?? '[]');
      if (value is! List) return [];
      return value.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = (map['product_id'] as num).toInt();
        final size = (map['size'] as num).toInt();
        final count = (map['quantity'] as num).toInt();
        return CartLine(id, size, count);
      }).where((line) => line.quantity > 0).toList();
    } catch (_) {
      return [];
    }
  }

  Set<int> get favorites {
    try {
      final value = jsonDecode(prefs.getString(_favoritesKey) ?? '[]');
      if (value is! List) return {};
      return value.map((e) => (e as num).toInt()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCart(List<CartLine> items) =>
      prefs.setString(
        _cartKey,
        jsonEncode([
          for (final line in items)
            {
              'product_id': line.productId,
              'size': line.size,
              'quantity': line.quantity,
            },
        ]),
      );

  Future<void> saveFavorites(Set<int> ids) =>
      prefs.setString(_favoritesKey, jsonEncode(ids.toList()));

  Future<void> clearShoppingData() async {
    await prefs.remove(_cartKey);
    await prefs.remove(_favoritesKey);
  }
}
