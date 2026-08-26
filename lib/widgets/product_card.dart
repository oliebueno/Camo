import 'package:flutter/material.dart';
import '../models/product.dart';

/// Tarjeta visual para mostrar un producto en el catálogo
/// Es un StatelessWidget porque solo recibe datos y callbacks (como un componente funcional en React)
class ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const ProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos el esquema de colores del tema actual
    final theme = Theme.of(context);
    final isSelected = cartQuantity > 0;

    return Card(
      elevation: isSelected ? 3 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icono representativo / Imagen según categoría
            _buildCategoryIcon(theme),
            const SizedBox(width: 14),

            // 2. Información del producto (Nombre, código, categoría y precio)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y Código de barras (Pills sutiles)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (product.barcode.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '#${product.barcode}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Nombre del producto
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Precio unitario y Stock
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          fontSize: 12,
                          color: product.stock > 10
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 3. Controles de cantidad (+ / -)
            _buildQuantityControls(theme),
          ],
        ),
      ),
    );
  }

  /// Construye el icono visual representativo
  Widget _buildCategoryIcon(ThemeData theme) {
    IconData icon;
    switch (product.category.toLowerCase()) {
      case 'víveres':
      case 'viveres':
      case 'alimentos':
        icon = Icons.shopping_basket_outlined;
        break;
      case 'bebidas':
        icon = Icons.local_drink_outlined;
        break;
      case 'limpieza':
        icon = Icons.cleaning_services_outlined;
        break;
      case 'cuidado personal':
        icon = Icons.face_retouching_natural_outlined;
        break;
      case 'lácteos':
      case 'lacteos':
        icon = Icons.egg_alt_outlined;
        break;
      default:
        icon = Icons.inventory_2_outlined;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: 26,
      ),
    );
  }

  /// Controles de cantidad: si es 0 muestra botón "+" grande; si ya está en carrito muestra [- 2 +]
  Widget _buildQuantityControls(ThemeData theme) {
    if (cartQuantity == 0) {
      return IconButton.filledTonal(
        onPressed: onAdd,
        tooltip: 'Agregar al carrito',
        icon: const Icon(Icons.add),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove, size: 18),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: theme.colorScheme.onPrimaryContainer,
          ),
          Text(
            '$cartQuantity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}
