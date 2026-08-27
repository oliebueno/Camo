import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
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

  /// Diálogo inteligente para Crear o Editar un Producto (Unidades o Peso/Kg)
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
    String unitType = productToEdit?.unit ?? 'unid'; // 'unid' o 'kg'

    // --- VARIABLES DE COSTO DE COMPRA ---
    double baseCostUSD = productToEdit?.costPrice ?? 0.0;
    final costUsdCtrl = TextEditingController(
        text: baseCostUSD > 0 ? baseCostUSD.toStringAsFixed(4) : '');
    final costBsCtrl = TextEditingController(
        text: baseCostUSD > 0
            ? (baseCostUSD * widget.exchangeRate).round().toString()
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
        text: baseSaleUSD > 0 ? baseSaleUSD.toStringAsFixed(4) : '');
    final priceBsCtrl = TextEditingController(
        text: baseSaleUSD > 0
            ? (baseSaleUSD * widget.exchangeRate).round().toString()
            : '');
    bool saleAddTax16 = false; // IVA en la venta (16%)

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isKg = unitType == 'kg';
            final int units = int.tryParse(unitsCtrl.text) ?? 1;
            final double margin =
                double.tryParse(marginCtrl.text.replaceAll(',', '.')) ?? 0.0;

            // 1. Costo real total (con IVA de compra si aplica)
            final double totalCostBoxUSD =
                costAddTax16 ? baseCostUSD * 1.16 : baseCostUSD;

            // 2. Costo unitario o por Kg real (4 decimales en USD)
            final double realUnitCostUSD =
                units > 0 ? (totalCostBoxUSD / units) : totalCostBoxUSD;
            final int realUnitCostBs =
                (realUnitCostUSD * widget.exchangeRate).round();

            // 3. Precio de venta final oficial (4 decimales en USD y Entero en Bs.)
            final double finalSaleUSD =
                saleAddTax16 ? baseSaleUSD * 1.16 : baseSaleUSD;
            final int finalSaleBsRounded =
                (finalSaleUSD * widget.exchangeRate).round();

            // Función para aplicar la sugerencia de costo + ganancia al precio de venta
            void applySuggestedPriceToSale() {
              if (realUnitCostUSD > 0) {
                final suggestedBase = margin > 0
                    ? realUnitCostUSD * (1 + (margin / 100))
                    : realUnitCostUSD;

                setDialogState(() {
                  baseSaleUSD = suggestedBase;
                  priceUsdCtrl.text = suggestedBase.toStringAsFixed(4);
                  priceBsCtrl.text =
                      (suggestedBase * widget.exchangeRate).round().toString();
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
                        '1. INFORMACIÓN GENERAL Y TIPO DE VENTA',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Selector de Tipo de Venta: Unidad vs Peso (Kg)
                      Container(
                        padding: const EdgeInsets.all(10),
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
                            const Text(
                              'Tipo de Venta:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'unid',
                                    icon: Icon(Icons.inventory_2_outlined),
                                    label: Text('Por Unidad'),
                                  ),
                                  ButtonSegment(
                                    value: 'kg',
                                    icon: Icon(Icons.scale_rounded),
                                    label: Text('Por Peso (Kg / Quesos)'),
                                  ),
                                ],
                                selected: {unitType},
                                onSelectionChanged: (val) {
                                  setDialogState(() {
                                    unitType = val.first;
                                  });
                                },
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: nameCtrl,
                              decoration: customInputDecoration(
                                label: isKg
                                    ? 'Nombre (Ej: Queso Blanco Paisa) *'
                                    : 'Nombre del Producto *',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: categoryCtrl,
                              decoration: customInputDecoration(
                                label: 'Categoría',
                                hintText: isKg ? 'Charcutería' : 'Víveres',
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
                                  Text(
                                    isKg
                                        ? 'Controlar Stock en Kilos (Kg)'
                                        : 'Controlar Existencias / Stock',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    trackStock
                                        ? (isKg
                                            ? 'Conteo de Kilos disponibles'
                                            : 'Conteo de unidades disponibles')
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
                                    label: isKg ? 'Total Kg *' : 'Cantidad *',
                                    suffixText: isKg ? 'Kg' : null,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2. Costo de Compra (Caja, Bulto o Bloque)
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
                                    Icon(
                                        isKg
                                            ? Icons.scale_rounded
                                            : Icons.shopping_bag_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      isKg
                                          ? '2. Costo de Compra (Bloque / Pieza entera)'
                                          : '2. Costo de Compra (Caja o Producto)',
                                      style: const TextStyle(
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
                                        costBsCtrl.text =
                                            (usd * widget.exchangeRate)
                                                .round()
                                                .toString();
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: isKg
                                          ? 'Costo Pieza (\$ USD)'
                                          : 'Costo Caja (\$ USD)',
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
                                            baseCostUSD.toStringAsFixed(4);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: isKg
                                          ? 'Costo Pieza (Bs.)'
                                          : 'Costo Caja (Bs.)',
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

                            // Unidades/Kg y Margen %
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: unitsCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setDialogState(() {}),
                                    decoration: customInputDecoration(
                                      label: isKg
                                          ? 'Peso Total de la Pieza (Kg)'
                                          : 'Unidades en Caja/Bulto',
                                      suffixText: isKg ? 'Kg' : null,
                                      hintText: isKg ? 'Ej: 5' : '1',
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
                                          isKg
                                              ? '➔ Costo real por Kilo (Kg):'
                                              : '➔ Costo real por unidad:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                        Text(
                                          '\$${realUnitCostUSD.toStringAsFixed(4)}${isKg ? "/Kg" : ""}  (Bs. $realUnitCostBs${isKg ? "/Kg" : ""})',
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

                      // 3. Fijación de Precio de Venta Oficial (por Unidad o por Kg)
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
                                Text(
                                  isKg
                                      ? '3. Precio de Venta por Kilo (Kg)'
                                      : '3. Precio de Venta Unitario',
                                  style: const TextStyle(
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
                                        priceBsCtrl.text =
                                            (usd * widget.exchangeRate)
                                                .round()
                                                .toString();
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: isKg
                                          ? 'Precio (\$ USD / Kg)'
                                          : 'Precio Venta (\$ USD)',
                                      prefixText: r'$ ',
                                      suffixText: isKg ? '/Kg' : null,
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
                                            baseSaleUSD.toStringAsFixed(4);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: isKg
                                          ? 'Precio (Bs. / Kg)'
                                          : 'Precio Venta (Bs.)',
                                      prefixText: 'Bs. ',
                                      suffixText: isKg ? '/Kg' : null,
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
                                              ? 'Se sumará 16% de IVA al precio final'
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
                                        isKg
                                            ? 'PRECIO FINAL OFICIAL POR KILO (Kg):'
                                            : 'PRECIO FINAL OFICIAL DE VENTA:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      if (saleAddTax16)
                                        Text(
                                          'Base: Bs. ${(baseSaleUSD * widget.exchangeRate).round()} + IVA: Bs. ${(baseSaleUSD * 0.16 * widget.exchangeRate).round()}',
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
                                        'Bs. $finalSaleBsRounded${isKg ? "/Kg" : ""}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '\$${finalSaleUSD.toStringAsFixed(4)} USD${isKg ? "/Kg" : ""}',
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
                          ? (isKg ? 'Charcutería' : 'General')
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
                      unit: unitType,
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

  void _openChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          void submitChange() async {
            final isValid =
                await AuthService.verifyPassword(currentPassCtrl.text);
            if (!isValid) {
              setDialogState(() {
                errorText = 'La contraseña actual no es correcta.';
              });
              return;
            }

            final newPass = newPassCtrl.text.trim();
            if (newPass.length < 4) {
              setDialogState(() {
                errorText = 'La nueva contraseña debe tener al menos 4 caracteres.';
              });
              return;
            }

            if (newPass != confirmPassCtrl.text.trim()) {
              setDialogState(() {
                errorText = 'Las nuevas contraseñas no coinciden.';
              });
              return;
            }

            await AuthService.changeAdminPassword(newPass);
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);

            if (!mounted) return;
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text('✅ Contraseña de administrador actualizada con éxito'),
                duration: Duration(seconds: 2),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.password_rounded,
                      color: theme.colorScheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cambiar Contraseña',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña Actual',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: Icon(Icons.check_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: submitChange,
                child: const Text('Guardar Contraseña'),
              ),
            ],
          );
        },
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
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Cambiar Contraseña de Administrador',
            onPressed: _openChangePasswordDialog,
          ),
          const SizedBox(width: 4),

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
                                        label: Text('Tipo / Unidad',
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
                                        label: Text(r'Costo Bulto/Bloque ($)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Unids/Kg',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text(r'Costo Unit/Kg ($)',
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
                                    final int priceInBsRounded =
                                        (product.price * widget.exchangeRate)
                                            .round();

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(product.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: product.isWeighted
                                                  ? Colors.amber.shade100
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              product.isWeighted
                                                  ? '⚖️ Peso (Kg)'
                                                  : 'Unidad',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: product.isWeighted
                                                    ? Colors.amber.shade900
                                                    : Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(product.category)),
                                        DataCell(Text(product.barcode.isEmpty
                                            ? '-'
                                            : product.barcode)),
                                        DataCell(Text(product.costPrice > 0
                                            ? '\$${product.costPrice.toStringAsFixed(4)}'
                                            : '-')),
                                        DataCell(
                                            Text('${product.unitsPerPackage}${product.isWeighted ? " Kg" : ""}')),
                                        DataCell(Text(product.unitCost > 0
                                            ? '\$${product.unitCost.toStringAsFixed(4)}'
                                            : '-')),
                                        DataCell(
                                          Text(
                                            '\$${product.price.toStringAsFixed(4)}${product.isWeighted ? "/Kg" : ""}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'Bs. $priceInBsRounded${product.isWeighted ? "/Kg" : ""}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          product.trackStock
                                              ? Text('${product.stock}${product.isWeighted ? " Kg" : ""}')
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
