import 'product.dart';

/// Representa un producto seleccionado por el vendedor en la calculadora de venta
class CartItem {
  final Product product;
  double quantity; // Soporta cantidades decimales para productos por peso (ej: 0.350 Kg)

  CartItem({
    required this.product,
    this.quantity = 1.0,
  });

  /// Subtotal en dólares ($)
  double get subtotal => product.price * quantity;

  /// Texto legible de la cantidad (ej: '350 g', '1.250 Kg' o '2 unids')
  String get formattedQuantity {
    if (product.isWeighted) {
      if (quantity < 1.0 && quantity > 0) {
        final grams = (quantity * 1000).round();
        return '$grams g';
      }
      return '${quantity.toStringAsFixed(3)} Kg';
    }
    return '${quantity.toInt()} ${quantity.toInt() == 1 ? "unid" : "unids"}';
  }

  /// Permite clonar o modificar la cantidad
  CartItem copyWith({
    Product? product,
    double? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
