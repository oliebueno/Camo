class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String barcode;
  final int stock;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.barcode,
    this.stock = 0, // Valor por defecto si no se pasa
    this.description = '',
  });

  /// Método para convertir un Map/JSON a un objeto Product
  /// (Equivalente a Jackson / Gson en Java o JSON.parse en JS)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'General',
      price: (json['price'] as num).toDouble(),
      barcode: json['barcode'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  /// Método para convertir el objeto a un Map (para guardarlo en base de datos o enviarlo por API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'barcode': barcode,
      'stock': stock,
      'description': description,
    };
  }

  /// Permite crear una copia del producto modificando solo ciertos campos
  /// (Inmutabilidad, como el spread operator `{ ...product, price: 10 }` en React/JS)
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? barcode,
    int? stock,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      stock: stock ?? this.stock,
      description: description ?? this.description,
    );
  }
}
