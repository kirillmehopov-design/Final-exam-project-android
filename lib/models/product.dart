class Product {
  final int id;
  final String name;
  final String brand;
  final double price;
  final double rating;
  final String category;
  final String description;
  final String imageUrl;
  final List<int> sizes;
  final List<String> tags;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.rating,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.sizes,
    required this.tags,
  });
}
