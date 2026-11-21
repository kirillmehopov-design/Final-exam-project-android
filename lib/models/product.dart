/// A product returned by https://fakestoreapi.com/products.
/// All API values are converted safely, even when the server sends null or
/// a price as an int instead of a double.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.additionalImages = const [],
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> additionalImages;

  factory Product.fromJson(Map<String, dynamic> json) {
    final ratingObject = json['rating'];
    final ratingJson = ratingObject is Map
        ? Map<String, dynamic>.from(ratingObject)
        : <String, dynamic>{};

    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.whereType<String>().where((url) => url.isNotEmpty).toList()
        : <String>[];

    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title'], 'Untitled product'),
      // An API may send 12 or 12.5. Casting via num first handles both.
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      description: _asString(json['description'], 'No description available.'),
      category: _asString(json['category'], 'Other'),
      imageUrl: _asString(json['image'], ''),
      rating: _asDouble(ratingJson['rate']),
      reviewCount: _asInt(ratingJson['count']),
      additionalImages: images,
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static String _asString(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  /// Three pages are required by the task. Fake Store API normally provides
  /// one image; in that case we reuse it for three different zoom/crop views.
  /// If an endpoint provides an images array, use its distinct URLs first.
  List<String> get galleryUrls {
    final unique = <String>[];
    if (imageUrl.isNotEmpty) unique.add(imageUrl);
    for (final image in additionalImages) {
      if (!unique.contains(image)) unique.add(image);
    }
    if (unique.isEmpty) return ['', '', ''];
    return List.generate(3, (index) => unique[index % unique.length]);
  }

  String get deepLink => 'narxoz://store/product/$id';
}

/// Fake Store API reports prices in US dollars.
String formatPrice(double price) => '\$' + price.toStringAsFixed(2);
