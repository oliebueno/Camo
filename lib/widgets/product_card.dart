import 'package:flutter/material.dart';
import '../models/product.dart';

/// Tarjeta visual para mostrar un producto con soporte para productos por unidad o por peso (Kg/g)
class ProductCard extends StatelessWidget {
  final Product product;
  final double cartQuantity;
  final double exchangeRate;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final Function(double)? onSetWeight;

  const ProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.exchangeRate,
    required this.onAdd,
    this.onRemove,
    this.onSetWeight,
  });

  void _openWeightSelector(BuildContext context) {
    final theme = Theme.of(context);
    final weightKgCtrl = TextEditingController(
      text: cartQuantity > 0 ? cartQuantity.toStringAsFixed(3) : '',
    );
    final weightGramsCtrl = TextEditingController(
      text: cartQuantity > 0 ? (cartQuantity * 1000).round().toString() : '',
    );
    final moneyBsCtrl = TextEditingController(
      text: cartQuantity > 0
          ? ((cartQuantity * product.price * exchangeRate).round()).toString()
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double currentKg =
                double.tryParse(weightKgCtrl.text.replaceAll(',', '.')) ?? 0.0;
            final double totalUSD = currentKg * product.price;
            final int totalBs = (totalUSD * exchangeRate).round();

            void setKg(double kg) {
              setModalState(() {
                weightKgCtrl.text = kg.toStringAsFixed(3);
                weightGramsCtrl.text = (kg * 1000).round().toString();
                moneyBsCtrl.text =
                    ((kg * product.price * exchangeRate).round()).toString();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.scale_rounded,
                                  color: theme.colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Precio: \$${product.price.toStringAsFixed(4)}/Kg (Bs. ${(product.price * exchangeRate).round()}/Kg)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetCtx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Botones Rápidos de Peso Frecuente
                    const Text(
                      'Pesos rápidos:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': '100 g', 'kg': 0.100},
                        {'label': '250 g (1/4 Kg)', 'kg': 0.250},
                        {'label': '500 g (1/2 Kg)', 'kg': 0.500},
                        {'label': '1 Kg', 'kg': 1.000},
                        {'label': '1.5 Kg', 'kg': 1.500},
                        {'label': '2 Kg', 'kg': 2.000},
                      ].map((item) {
                        return ActionChip(
                          label: Text(item['label'] as String),
                          onPressed: () => setKg(item['kg'] as double),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Entrada exacta por Gramos o Kilogramos
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightGramsCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final grams = double.tryParse(val) ?? 0.0;
                              final kg = grams / 1000;
                              setModalState(() {
                                weightKgCtrl.text =
                                    kg > 0 ? kg.toStringAsFixed(3) : '';
                                moneyBsCtrl.text = kg > 0
                                    ? ((kg * product.price * exchangeRate)
                                            .round())
                                        .toString()
                                    : '';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Gramos (g)',
                              suffixText: 'g',
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.sync_alt_rounded, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightKgCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (val) {
                              final kg = double.tryParse(
                                      val.replaceAll(',', '.')) ??
                                  0.0;
                              setModalState(() {
                                weightGramsCtrl.text = kg > 0
                                    ? (kg * 1000).round().toString()
                                    : '';
                                moneyBsCtrl.text = kg > 0
                                    ? ((kg * product.price * exchangeRate)
                                            .round())
                                        .toString()
                                    : '';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Kilos (Kg)',
                              suffixText: 'Kg',
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // O pedir por dinero en Bolívares (ej: "Deme 50 Bs. de queso")
                    TextField(
                      controller: moneyBsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (val) {
                        final bs =
                            double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                        final priceInBs = product.price * exchangeRate;
                        final kg = priceInBs > 0 ? (bs / priceInBs) : 0.0;
                        setModalState(() {
                          weightKgCtrl.text =
                              kg > 0 ? kg.toStringAsFixed(3) : '';
                          weightGramsCtrl.text =
                              kg > 0 ? (kg * 1000).round().toString() : '';
                        });
                      },
                      decoration: InputDecoration(
                        labelText:
                            'O ingresar por monto en Bs. (ej: "50 Bs. de queso")',
                        prefixText: 'Bs. ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Resumen de cobro por el peso ingresado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total por este peso:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                currentKg > 0 ? (currentKg < 1 ? "${(currentKg * 1000).round()} g" : "${currentKg.toStringAsFixed(3)} Kg") : "0 Kg",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Bs. $totalBs',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '\$${totalUSD.toStringAsFixed(4)} USD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botones de acción
                    Row(
                      children: [
                        if (cartQuantity > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                onSetWeight?.call(0.0);
                                Navigator.pop(bottomSheetCtx);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Quitar'),
                            ),
                          ),
                        if (cartQuantity > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: currentKg > 0
                                ? () {
                                    onSetWeight?.call(currentKg);
                                    Navigator.pop(bottomSheetCtx);
                                  }
                                : null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(cartQuantity > 0
                                ? 'Actualizar Peso'
                                : 'Agregar a la Venta'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = cartQuantity > 0;
    final int priceInBsRounded = (product.price * exchangeRate).round();

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
      child: InkWell(
        onTap: product.isWeighted ? () => _openWeightSelector(context) : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icono según categoría
              _buildCategoryIcon(theme),
              const SizedBox(width: 14),

              // 2. Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría, Badge de Peso y Código de barras
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
                        if (product.isWeighted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.scale_rounded,
                                    size: 12, color: Colors.amber.shade900),
                                const SizedBox(width: 3),
                                Text(
                                  'Por Peso (Kg)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

                    // Precios ($ 4 decimales y Bs. entero)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(4)}${product.isWeighted ? "/Kg" : ""}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bs. $priceInBsRounded${product.isWeighted ? "/Kg" : ""}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const Spacer(),
                        _buildStockWidget(),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Controles de cantidad (+ / - o selector de peso)
              _buildQuantityControls(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockWidget() {
    if (!product.trackStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Disponible',
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Text(
      'Stock: ${product.stock}${product.isWeighted ? " Kg" : ""}',
      style: TextStyle(
        fontSize: 12,
        color: product.stock > 10
            ? Colors.green.shade700
            : Colors.orange.shade800,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCategoryIcon(ThemeData theme) {
    IconData icon;
    switch (product.category.toLowerCase()) {
      case 'víveres':
      case 'viveres':
      case 'alimentos':
        icon = Icons.shopping_basket_outlined;
        break;
      case 'charcutería':
      case 'charcuteria':
      case 'quesos':
        icon = Icons.lunch_dining_outlined;
        break;
      case 'carnes':
      case 'carnicería':
      case 'carniceria':
        icon = Icons.set_meal_outlined;
        break;
      case 'verduras':
      case 'frutas':
        icon = Icons.eco_outlined;
        break;
      case 'bebidas':
        icon = Icons.local_drink_outlined;
        break;
      case 'limpieza':
        icon = Icons.cleaning_services_outlined;
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

  Widget _buildQuantityControls(BuildContext context, ThemeData theme) {
    if (product.isWeighted) {
      if (cartQuantity == 0) {
        return FilledButton.tonalIcon(
          onPressed: () => _openWeightSelector(context),
          icon: const Icon(Icons.scale_rounded, size: 16),
          label: const Text('Pesar'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      final label = cartQuantity < 1.0
          ? '${(cartQuantity * 1000).round()} g'
          : '${cartQuantity.toStringAsFixed(3)} Kg';

      return ActionChip(
        avatar: const Icon(Icons.scale_rounded, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primaryContainer,
        onPressed: () => _openWeightSelector(context),
      );
    }

    // Para productos por unidad
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
            '${cartQuantity.toInt()}',
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
