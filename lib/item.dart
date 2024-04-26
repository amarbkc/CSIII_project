class Product {
  final int id;
  final String name;
  final String price;
  final String targetPrice;
  final String currentPrice;
  final String image;
  final String url;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.targetPrice,
    required this.currentPrice,
    required this.image,
    required this.url,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      targetPrice: json['target_price'],
      currentPrice: json['current_price'],
      image: json['image'],
      url: json['url'],
    );
  }

}