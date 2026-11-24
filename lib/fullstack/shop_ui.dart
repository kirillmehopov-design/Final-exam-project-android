import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'shop_cubit.dart';
import '../providers/theme_cubit.dart';
import '../providers/notes_vault_provider.dart';
import '../screens/notes_vault_screen.dart';

part 'screens/app_shell.dart';
part 'screens/catalog_screen.dart';
part 'screens/stores_screen.dart';
part 'screens/transfer_requests_screen.dart';
part 'screens/store_detail_screen.dart';
part 'screens/product_screen.dart';
part 'screens/favorites_screen.dart';
part 'screens/cart_screen.dart';
part 'screens/orders_screen.dart';
part 'screens/inventory_screen.dart';
part 'screens/stats_screen.dart';
part 'screens/profile_screen.dart';
part 'widgets/product_image.dart';
part 'widgets/product_tile.dart';


class SneakerDesign {
  static const ink = Color(0xFF181A19);
  static const canvas = Color(0xFFFAF9F6);
  static const orange = Color(0xFFFF633F);
  static const muted = Color(0xFF70726D);
  static const line = Color(0xFFECEAE5);
  static const imageSurface = Color(0xFFF2F0EB);

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: brightness,
      primary: dark ? const Color(0xFFFFAB8C) : ink,
      secondary: orange,
      surface: dark ? const Color(0xFF1A1A1A) : Colors.white,
    );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: dark ? Colors.white24 : line),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF121212) : canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: dark ? Colors.white : ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF232323) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dark ? Colors.white12 : line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF252525) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: orange, width: 1.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 17),
          side: BorderSide(color: dark ? Colors.white30 : line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: dark ? Colors.white24 : line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      dividerTheme: DividerThemeData(color: dark ? Colors.white12 : line),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF1A1A1A) : Colors.white,
        indicatorColor: dark ? const Color(0xFF45322C) : const Color(0xFFFFE9E1),
        height: 70,
      ),
    );
  }

  static Widget eyebrow(String label) => Text(label.toUpperCase(),
    style: const TextStyle(color: orange, fontSize: 11,
      fontWeight: FontWeight.w900, letterSpacing: 2.5));
}

String money(int cents) {
  final digits = (cents / 100).round().toString();
  final groups = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return '$groups ₸';
}
int amount(Json p) => p['sale_price_cents'] as int;
