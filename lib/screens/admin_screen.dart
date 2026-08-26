import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

/// Panel de Administración de Productos (Optimizado para Escritorio / Windows)
class AdminScreen extends StatefulWidget {
  final double exchangeRate;
  final VoidCallback onProductsChanged;

  const AdminScreen({
    super.key,
    required this.exchangeRate,
    required this.onProductsChanged,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.getProducts();
      if (mounted) {
        setState(() {
          _products = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['Todos', ...cats];
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchCat = _selectedCategory == 'Todos' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();
      final q = _searchQuery.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          product.barcode.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();
  }

  /// Diálogo inteligente para Crear o Editar un Producto
  void _openProductFormDialog({Product? productToEdit}) {
    final isEditing = productToEdit != null;

    final nameCtrl = TextEditingController(text: productToEdit?.name ?? '');
    final categoryCtrl =
        TextEditingController(text: productToEdit?.category ?? 'Víveres');
    final barcodeCtrl =
        TextEditingController(text: productToEdit?.barcode ?? '');
    final stockCtrl =
        TextEditingController(text: productToEdit?.stock.toString() ?? '0');
    final descCtrl =
        TextEditingController(text: productToEdit?.description ?? '');

    bool trackStock = productToEdit?.trackStock ?? true;

    // --- VARIABLES DE COSTO DE COMPRA ---
    double baseCostUSD = productToEdit?.costPrice ?? 0.0;
    final costUsdCtrl = TextEditingController(
        text: baseCostUSD > 0 ? baseCostUSD.toStringAsFixed(2) : '');
    final costBsCtrl = TextEditingController(
        text: baseCostUSD > 0
            ? (baseCostUSD * widget.exchangeRate).toStringAsFixed(2)
            : '');
    bool costAddTax16 = false; // IVA en la compra (16%)
    final unitsCtrl = TextEditingController(
        text: productToEdit?.unitsPerPackage.toString() ?? '1');
    final marginCtrl = TextEditingController(
        text: productToEdit?.profitMargin != null &&
                productToEdit!.profitMargin > 0
            ? productToEdit.profitMargin.toStringAsFixed(0)
            : '');

    // --- VARIABLES DE PRECIO DE VENTA ---
    double baseSaleUSD = productToEdit?.price ?? 0.0;
    final priceUsdCtrl = TextEditingController(
        text: baseSaleUSD > 0 ? baseSaleUSD.toStringAsFixed(2) : '');
    final priceBsCtrl = TextEditingController(
        text: baseSaleUSD > 0
            ? (baseSaleUSD * widget.exchangeRate).toStringAsFixed(2)
            : '');
    bool saleAddTax16 = false; // IVA en la venta (16%)

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int units = int.tryParse(unitsCtrl.text) ?? 1;
            final double margin =
                double.tryParse(marginCtrl.text.replaceAll(',', '.')) ?? 0.0;

            // 1. Costo real total de la caja (con IVA de compra si aplica)
            final double totalCostBoxUSD =
                costAddTax16 ? baseCostUSD * 1.16 : baseCostUSD;

            // 2. Costo unitario real
            final double realUnitCostUSD =
                units > 0 ? (totalCostBoxUSD / units) : totalCostBoxUSD;
            final double realUnitCostBs =
                realUnitCostUSD * widget.exchangeRate;

            // 3. Precio de venta final oficial
            final double finalSaleUSD =
                saleAddTax16 ? baseSaleUSD * 1.16 : baseSaleUSD;
            final double finalSaleBs = finalSaleUSD * widget.exchangeRate;

            // Función para aplicar la sugerencia de costo + ganancia al precio de venta
            void applySuggestedPriceToSale() {
              if (realUnitCostUSD > 0) {
                final suggestedBase = margin > 0
                    ? realUnitCostUSD * (1 + (margin / 100))
                    : realUnitCostUSD;

                setDialogState(() {
                  baseSaleUSD = suggestedBase;
                  priceUsdCtrl.text = suggestedBase.toStringAsFixed(2);
                  priceBsCtrl.text =
                      (suggestedBase * widget.exchangeRate).toStringAsFixed(2);
                });
              }
            }

            InputDecoration customInputDecoration({
              required String label,
              String? prefixText,
              String? suffixText,
              String? hintText,
            }) {
              return InputDecoration(
                labelText: label,
                prefixText: prefixText,
                suffixText: suffixText,
                hintText: hintText,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              );
            }

            return AlertDialog(
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.add_box_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Editar Producto' : 'Registrar Nuevo Producto',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 660,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Datos Básicos
                      Text(
                        '1. INFORMACIÓN GENERAL',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: nameCtrl,
                              decoration: customInputDecoration(
                                label: 'Nombre del Producto *',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: categoryCtrl,
                              decoration: customInputDecoration(
                                label: 'Categoría',
                                hintText: 'Ej: Víveres, Bebidas',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: barcodeCtrl,
                        decoration: customInputDecoration(
                          label: 'Código de Barras (Opcional)',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Control de Inventario / Stock
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              trackStock
                                  ? Icons.inventory_rounded
                                  : Icons.all_inclusive_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Controlar Existencias / Stock',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    trackStock
                                        ? 'Llevar conteo de unidades disponibles'
                                        : 'Stock ilimitado (disponibilidad continua)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: trackStock,
                              onChanged: (val) {
                                setDialogState(() {
                                  trackStock = val;
                                });
                              },
                            ),
                            if (trackStock) ...[
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: customInputDecoration(
                                    label: 'Cantidad *',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2. Costo de Compra / Caja (Soporte Dual $ y Bs. + IVA Compra 16%)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_bag_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '2. Costo de Compra (Caja o Producto)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'BCV: Bs. ${widget.exchangeRate.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Entradas de Costo en $ o en Bs.
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: costUsdCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (val) {
                                      final usd = double.tryParse(
                                              val.replaceAll(',', '.')) ??
                                          0.0;
                                      setDialogState(() {
                                        baseCostUSD = usd;
                                        costBsCtrl.text = (usd *
                                                widget.exchangeRate)
                                            .toStringAsFixed(2);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: 'Costo en Dólares (\$ USD)',
                                      prefixText: r'$ ',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                const Icon(Icons.sync_alt_rounded, size: 20),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: TextField(
                                    controller: costBsCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (val) {
                                      final bs = double.tryParse(
                                              val.replaceAll(',', '.')) ??
                                          0.0;
                                      setDialogState(() {
                                        baseCostUSD = widget.exchangeRate > 0
                                            ? bs / widget.exchangeRate
                                            : 0.0;
                                        costUsdCtrl.text =
                                            baseCostUSD.toStringAsFixed(2);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: 'Costo en Bolívares (Bs.)',
                                      prefixText: 'Bs. ',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Checkbox IVA en la Compra (16%)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: costAddTax16,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        costAddTax16 = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      costAddTax16
                                          ? 'Me cobraron +16% de IVA en la factura de compra'
                                          : 'El costo de compra ya incluye IVA (o es exento)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Unidades por caja y Margen %
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: unitsCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setDialogState(() {}),
                                    decoration: customInputDecoration(
                                      label: 'Unidades en Caja/Bulto',
                                      hintText: '1 si es unidad suelta',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: marginCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (_) => setDialogState(() {}),
                                    decoration: customInputDecoration(
                                      label: '% Ganancia Deseada',
                                      suffixText: '%',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (totalCostBoxUSD > 0) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '➔ Costo unitario real:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                        Text(
                                          '\$${realUnitCostUSD.toStringAsFixed(2)}  (Bs. ${realUnitCostBs.toStringAsFixed(2)})',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: applySuggestedPriceToSale,
                                      icon: const Icon(
                                          Icons.arrow_downward_rounded,
                                          size: 16),
                                      label: const Text('Calcular Venta'),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3. Fijación de Precio de Venta Oficial (Directo en $ o en Bs. + IVA Venta 16%)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sell_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  '3. Precio de Venta Unitario (El que verá el vendedor)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Inputs interactivos de venta en $ o en Bs.
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: priceUsdCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (val) {
                                      final usd = double.tryParse(
                                              val.replaceAll(',', '.')) ??
                                          0.0;
                                      setDialogState(() {
                                        baseSaleUSD = usd;
                                        priceBsCtrl.text = (usd *
                                                widget.exchangeRate)
                                            .toStringAsFixed(2);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: 'Precio Venta (\$ USD)',
                                      prefixText: r'$ ',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                const Icon(Icons.sync_alt_rounded, size: 20),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: TextField(
                                    controller: priceBsCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (val) {
                                      final bs = double.tryParse(
                                              val.replaceAll(',', '.')) ??
                                          0.0;
                                      setDialogState(() {
                                        baseSaleUSD = widget.exchangeRate > 0
                                            ? bs / widget.exchangeRate
                                            : 0.0;
                                        priceUsdCtrl.text =
                                            baseSaleUSD.toStringAsFixed(2);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: 'Precio Venta (Bs.)',
                                      prefixText: 'Bs. ',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Selector de IVA Venta (16%)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: saleAddTax16,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        saleAddTax16 = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'El monto de venta es Base Imponible (Agregar +16% IVA)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          saleAddTax16
                                              ? 'Se sumará 16% de IVA al precio final al cliente'
                                              : 'El precio ingresado ya es el monto final a cobrar (o exento)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Resumen Final Oficial
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PRECIO FINAL OFICIAL DE VENTA:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      if (saleAddTax16)
                                        Text(
                                          'Base: Bs. ${(baseSaleUSD * widget.exchangeRate).toStringAsFixed(2)} + IVA: Bs. ${(baseSaleUSD * 0.16 * widget.exchangeRate).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Bs. ${finalSaleBs.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '\$${finalSaleUSD.toStringAsFixed(2)} USD',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                      isEditing ? 'Guardar Cambios' : 'Registrar Producto'),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('El nombre del producto es obligatorio')),
                      );
                      return;
                    }

                    if (finalSaleUSD <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Ingresa un precio de venta válido mayor a 0')),
                      );
                      return;
                    }

                    final newProd = Product(
                      id: isEditing ? productToEdit.id : '',
                      name: name,
                      category: categoryCtrl.text.trim().isEmpty
                          ? 'General'
                          : categoryCtrl.text.trim(),
                      price: finalSaleUSD,
                      costPrice: totalCostBoxUSD,
                      unitsPerPackage: units,
                      profitMargin: margin,
                      barcode: barcodeCtrl.text.trim(),
                      trackStock: trackStock,
                      stock: trackStock
                          ? (int.tryParse(stockCtrl.text) ?? 0)
                          : 0,
                      description: descCtrl.text.trim(),
                    );

                    Navigator.pop(context);

                    if (isEditing) {
                      await SupabaseService.updateProduct(newProd);
                    } else {
                      await SupabaseService.createProduct(newProd);
                    }

                    _loadProducts();
                    widget.onProductsChanged();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${product.name}" de la base de datos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.deleteProduct(product.id);
              _loadProducts();
              widget.onProductsChanged();
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize_rounded),
            SizedBox(width: 10),
            Text(
              'Panel de Administración (Catálogo Central)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Chip(
            avatar: const Icon(Icons.currency_exchange, size: 16),
            label: Text(
              'BCV: Bs. ${widget.exchangeRate.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sincronizar con Supabase',
            onPressed: _loadProducts,
          ),
          const SizedBox(width: 8),

          FilledButton.icon(
            onPressed: () => _openProductFormDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo Producto'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filtros superiores
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código de barras...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tabla de productos estilo Desktop
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('No hay productos registrados.'))
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor:
                                      WidgetStateProperty.all(
                                    theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                  ),
                                  columns: const [
                                    DataColumn(
                                        label: Text('Producto',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Categoría',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Código',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text(r'Costo Caja ($)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Unids/Caja',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text(r'Costo Unit ($)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text(r'P. Venta ($)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('P. Venta (Bs.)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Stock',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Acciones',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filtered.map((product) {
                                    final priceInBs =
                                        product.price * widget.exchangeRate;

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(product.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600))),
                                        DataCell(Text(product.category)),
                                        DataCell(Text(product.barcode.isEmpty
                                            ? '-'
                                            : product.barcode)),
                                        DataCell(Text(product.costPrice > 0
                                            ? '\$${product.costPrice.toStringAsFixed(2)}'
                                            : '-')),
                                        DataCell(
                                            Text('${product.unitsPerPackage}')),
                                        DataCell(Text(product.unitCost > 0
                                            ? '\$${product.unitCost.toStringAsFixed(2)}'
                                            : '-')),
                                        DataCell(
                                          Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'Bs. ${priceInBs.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          product.trackStock
                                              ? Text('${product.stock}')
                                              : Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Ilimitado',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 20),
                                                tooltip: 'Editar',
                                                onPressed: () =>
                                                    _openProductFormDialog(
                                                        productToEdit: product),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Eliminar',
                                                onPressed: () =>
                                                    _confirmDelete(product),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
