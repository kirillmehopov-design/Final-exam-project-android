import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fullstack/api_client.dart';
import 'fullstack/shop_cubit.dart';
import 'fullstack/shop_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  runApp(
    BlocProvider(
      create: (_) => ShopCubit(api)..initialize(),
      child: const SneakerHubFullstackApp(),
    ),
  );
}
