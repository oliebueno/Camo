import 'product.dart';

/// Representa un producto seleccionado por el vendedor en la calculadora de venta
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Getter computado: Calcula el subtotal en tiempo real
  /// En Dart, `double get subtotal => ...` es una propiedad calculada (como un getter en Java)
  double get subtotal => product.price * quantity;

  /// Permite clonar o modificar la cantidad
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
