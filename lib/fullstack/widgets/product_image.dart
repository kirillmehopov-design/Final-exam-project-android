part of '../shop_ui.dart';

Widget photo(String url, {double height = 170}) => Image.network(
  url,
  height: height,
  width: double.infinity,
  fit: BoxFit.contain,
  errorBuilder: (_, __, ___) => Container(
    height: height,
    color: SneakerDesign.imageSurface,
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported_outlined,
      size: 36, color: SneakerDesign.muted),
  ),
);
