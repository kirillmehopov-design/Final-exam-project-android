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

String money(int cents) {
  final digits = (cents / 100).round().toString();
  final groups = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return groups + ' ₸';
}
int amount(Json p) => p['sale_price_cents'] as int;
