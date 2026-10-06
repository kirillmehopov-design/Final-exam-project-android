import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/size_selector.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool initialFavorite;
  final VoidCallback onToggleFavorite;
  final void Function(Product product, int size) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.initialFavorite,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int? selectedSize;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.initialFavorite;
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    widget.onToggleFavorite();
  }

  void addToCart() {
    if (selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size first.'),
        ),
      );
      return;
    }

    widget.onAddToCart(widget.product, selectedSize!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.product.name}, size $selectedSize added to cart.',
        ),
      ),
    );
  }

  Widget buildImageSection() {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.network(
              widget.product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFFEDEDED),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: Colors.white.withValues(alpha: 0.94),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Favorite',
                onPressed: toggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                widget.product.brand,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              widget.product.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '\$${widget.product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Text(
          widget.product.description,
          style: const TextStyle(
            height: 1.6,
            color: Colors.black54,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Select size',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        SizeSelector(
          sizes: widget.product.sizes,
          selectedSize: selectedSize,
          onSelected: (size) {
            setState(() {
              selectedSize = size;
            });
          },
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: addToCart,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              selectedSize == null
                  ? 'Choose Size & Add to Cart'
                  : 'Add Size $selectedSize to Cart',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: buildImageSection()),
                            const SizedBox(width: 34),
                            Expanded(child: buildInfoSection()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildImageSection(),
                            const SizedBox(height: 26),
                            buildInfoSection(),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
