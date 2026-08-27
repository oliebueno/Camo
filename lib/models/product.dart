/// Modelo de Producto con soporte para venta por unidad o por peso (Kg/g), cálculo por caja y stock
class Product {
  final String id;
  final String name;
  final String category;
  final double price; // Precio de venta ($ por unidad o por Kg)
  final double costPrice; // Costo de la caja, saco o bloque ($)
  final int unitsPerPackage; // Cantidad de unidades o Kg por bulto/bloque
  final double profitMargin; // % de ganancia
  final String barcode;
  final bool trackStock; // Habilitar o deshabilitar control de inventario
  final int stock; // Cantidad en existencia
  final String description;
  final String unit; // 'unid' (Por Unidad) o 'kg' (Por Peso / Kilogramo)

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.costPrice = 0.0,
    this.unitsPerPackage = 1,
    this.profitMargin = 0.0,
    required this.barcode,
    this.trackStock = true,
    this.stock = 0,
    this.description = '',
    this.unit = 'unid',
  });

  /// Indica si el producto se vende pesado (Queso, Jamón, Carne, Verduras)
  bool get isWeighted => unit == 'kg';

  /// Costo unitario base calculado (Costo Caja / Unidades o Kg)
  double get unitCost =>
      unitsPerPackage > 0 ? (costPrice / unitsPerPackage) : costPrice;

  /// De JSON (Supabase o Cache Local) a Objeto Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      category: json['category'] as String? ?? 'General',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      unitsPerPackage: (json['units_per_package'] as num?)?.toInt() ?? 1,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      barcode: json['barcode'] as String? ?? '',
      trackStock: json['track_stock'] as bool? ?? true,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      unit: json['unit'] as String? ?? 'unid',
    );
  }

  /// De Objeto Product a Map JSON
  Map<String, dynamic> toJson({bool includeId = true}) {
    final data = <String, dynamic>{
      'name': name,
      'category': category,
      'price': price,
      'cost_price': costPrice,
      'units_per_package': unitsPerPackage,
      'profit_margin': profitMargin,
      'barcode': barcode,
      'track_stock': trackStock,
      'stock': stock,
      'description': description,
      'unit': unit,
    };
    if (includeId && id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    double? costPrice,
    int? unitsPerPackage,
    double? profitMargin,
    String? barcode,
    bool? trackStock,
    int? stock,
    String? description,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      profitMargin: profitMargin ?? this.profitMargin,
      barcode: barcode ?? this.barcode,
      trackStock: trackStock ?? this.trackStock,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      unit: unit ?? this.unit,
    );
  }
}
