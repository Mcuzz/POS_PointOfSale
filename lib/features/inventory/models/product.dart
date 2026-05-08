class Product {
  final int? id;
  final String name;
  final String? sku;
  final String category;
  final double price;
  final int stock;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    this.sku,
    required this.category,
    required this.price,
    required this.stock,
    this.imagePath,
  });

  // Convierte un objeto Product en un Map para insertarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'price': price,
      'stock': stock,
      'image_path': imagePath,
    };
  }

  // Crea un objeto Product a partir de un Map obtenido de SQLite
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      category: map['category'],
      price: map['price'],
      stock: map['stock'],
      imagePath: map['image_path'],
    );
  }

  // Permite clonar el producto modificando solo algunos campos (útil para editar)
  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? category,
    double? price,
    int? stock,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}