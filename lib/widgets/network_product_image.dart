import 'package:flutter/material.dart';

class NetworkProductImage extends StatelessWidget {
  const NetworkProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
  });

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: SizedBox(
          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2),
        ));
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() => const Center(
    child: Icon(Icons.image_not_supported_outlined,
        size: 34, color: Colors.blueGrey),
  );
}
