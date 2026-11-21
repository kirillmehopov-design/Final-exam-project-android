import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shop_cubit.dart';
import '../providers/theme_cubit.dart';

part 'screens/app_shell.dart';
part 'screens/catalog_screen.dart';
part 'screens/product_screen.dart';
part 'screens/favorites_screen.dart';
part 'screens/cart_screen.dart';
part 'screens/orders_screen.dart';
part 'screens/inventory_screen.dart';
part 'screens/stats_screen.dart';
part 'screens/profile_screen.dart';
part 'widgets/product_image.dart';
part 'widgets/product_tile.dart';

String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
int amount(Json p) => p['sale_price_cents'] as int;

