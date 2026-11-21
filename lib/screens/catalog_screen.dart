import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_api.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/connection_error_view.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'notes_vault_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.api});
  final ProductApi? api;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final ProductApi _api;
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ProductApi();
    _fetchProducts();
  }

  Future<void> _fetchProducts({bool showSpinner = true}) async {
    final currentRequest = ++_requestNumber;
    setState(() {
      _error = null;
      if (showSpinner) _loading = true;
    });
    try {
      final products = await _api.fetchProducts();
      if (!mounted || currentRequest != _requestNumber) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } on ProductApiException catch (error) {
      if (!mounted || currentRequest != _requestNumber) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || currentRequest != _requestNumber) return;
      setState(() {
        _error = 'Could not connect. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    ++_requestNumber;
    super.dispose();
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('loading-spinner')),
      );
    }
    if (_error != null) {
      return ConnectionErrorView(
        message: _error!,
        onRetry: () => _fetchProducts(),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inventory_2_outlined, size: 60),
          const SizedBox(height: 12),
          const Text('No products available'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _fetchProducts(),
            child: const Text('Reload products'),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchProducts(showSpinner: false),
      child: ListView.separated(
        key: const PageStorageKey<String>('api-catalog-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final product = _products[index];
          return ProductCard(
            key: ValueKey(product.id),
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SneakerHub'),
        actions: [
          IconButton(
            tooltip: 'Offline Notes & Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotesVaultScreen(),
              ),
            ),
            icon: const Icon(Icons.note_alt_outlined),
          ),
          IconButton(
            tooltip: 'Reload products',
            onPressed: () => _fetchProducts(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          CartBadgeButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }
}
