part of '../shop_ui.dart';

Widget photo(String url, {double height = 170}) => Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height, color: const Color(0xFFE8EAF0),
        alignment: Alignment.center, child: const Icon(Icons.image_not_supported_outlined, size: 42)),
    );
