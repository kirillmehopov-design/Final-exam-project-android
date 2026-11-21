import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/notes_vault_provider.dart';
import 'screens/catalog_screen.dart';

Future<void> main() async {
  // LW11: Load theme, profile and notes BEFORE rendering the first frame.
  WidgetsFlutterBinding.ensureInitialized();
  final vault = await NotesVaultProvider.load();
  final cart = await CartProvider.load();
  runApp(GlobalCartApp(vault: vault, cart: cart));
}

class GlobalCartApp extends StatelessWidget {
  const GlobalCartApp({super.key, required this.vault, required this.cart});

  final NotesVaultProvider vault;
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: cart),
        ChangeNotifierProvider<NotesVaultProvider>.value(value: vault),
      ],
      child: Consumer<NotesVaultProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'SneakerHub',
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF315BD8),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(centerTitle: false),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF315BD8),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(centerTitle: false),
          ),
          home: const CatalogScreen(),
        ),
      ),
    );
  }
}
