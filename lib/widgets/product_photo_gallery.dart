import 'package:flutter/material.dart';

import '../models/product.dart';
import 'network_product_image.dart';

class ProductPhotoGallery extends StatefulWidget {
  const ProductPhotoGallery({super.key, required this.product});
  final Product product;

  @override
  State<ProductPhotoGallery> createState() => _ProductPhotoGalleryState();
}

class _ProductPhotoGalleryState extends State<ProductPhotoGallery> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.galleryUrls;
    final isSamePhoto = images.toSet().length == 1;

    return Column(children: [
      SizedBox(
        height: 304,
        child: Stack(children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              // The API contains a single image. Three slides display
              // the same product photo at different zoom/crop levels.
              final scale = isSamePhoto ? (index == 0 ? 1.0 : index == 1 ? 1.25 : 1.55) : 1.0;
              final alignment = index == 2 ? Alignment.centerRight : Alignment.center;
              final photo = ClipRect(child: Transform.scale(
                scale: scale, alignment: alignment,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: NetworkProductImage(url: images[index]),
                ),
              ));
              return ColoredBox(
                color: Colors.white,
                // Only the active page owns the shared Hero tag.
                // This also enables the reverse Hero transition after a swipe.
                child: index == _currentPage
                  ? Hero(tag: 'product_image_${widget.product.id}', child: photo)
                  : photo,
              );
            },
          ),
          Positioned(
            right: 14, bottom: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(170),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    '${_currentPage + 1} / ${images.length}',
                    key: ValueKey(_currentPage),
                    style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 13),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var index = 0; index < images.length; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Colors.blueGrey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ]),
      if (isSamePhoto)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Original • Zoom • Close-up',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ),
    ]);
  }
}
