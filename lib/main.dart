import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fullstack/api_client.dart';
import 'fullstack/shop_cubit.dart';
import 'fullstack/shop_ui.dart';
import 'providers/local_store.dart';
import 'providers/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  final api = ApiClient();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(store),
        ),
        BlocProvider<ShopCubit>(
          create: (_) => ShopCubit(api, store)..initialize(),
        ),
      ],
      child: const SneakerHubFullstackApp(),
    ),
  );
}
