class ApiProduct {
  final int id;
  final String name;
  final String brand;
  final double price;
  final String imageUrl;

  const ApiProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      brand: json['brand'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
    );
  }

  static Map<String, dynamic> normalize(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['price'] ??= (json['sale_price_cents'] as num) / 100.0;
    return normalized;
  }
}
