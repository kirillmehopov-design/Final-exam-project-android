import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fullstack/api_client.dart';
import 'fullstack/shop_cubit.dart';
import 'fullstack/shop_ui.dart';
import 'providers/local_store.dart';
import 'providers/notes_vault_provider.dart';
import 'providers/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Preserve the Lab 11 theme if this is the first run of the new UI.
  final previousDark = prefs.getBool(NotesVaultProvider.themeKey);
  if (prefs.getBool('sneakerhub.theme.dark') == null && previousDark != null) {
    await prefs.setBool('sneakerhub.theme.dark', previousDark);
  }

  final vault = await NotesVaultProvider.load();
  final store = LocalStore(prefs);
  final api = ApiClient();

  runApp(
    ChangeNotifierProvider<NotesVaultProvider>.value(
      value: vault,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(store)),
          BlocProvider<ShopCubit>(
            create: (_) => ShopCubit(api, store)..initialize(),
          ),
        ],
        child: const SneakerHubFullstackApp(),
      ),
    ),
  );
}
