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

  /// Diálogo inteligente para Crear o Editar un Producto (Diseño Tonal Moderno sin fondos blancos duros)
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

    final costPriceCtrl = TextEditingController(
        text: productToEdit?.costPrice != null && productToEdit!.costPrice > 0
            ? productToEdit.costPrice.toStringAsFixed(2)
            : '');
    final unitsCtrl = TextEditingController(
        text: productToEdit?.unitsPerPackage.toString() ?? '1');
    final marginCtrl = TextEditingController(
        text: productToEdit?.profitMargin != null &&
                productToEdit!.profitMargin > 0
            ? productToEdit.profitMargin.toStringAsFixed(0)
            : '');

    final priceUsdCtrl = TextEditingController(
        text: productToEdit?.price != null && productToEdit!.price > 0
            ? productToEdit.price.toStringAsFixed(2)
            : '');
    final priceBsCtrl = TextEditingController(
        text: productToEdit?.price != null && productToEdit!.price > 0
            ? (productToEdit.price * widget.exchangeRate).toStringAsFixed(2)
            : '');

    bool addTax16 = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            double baseUSD =
                double.tryParse(priceUsdCtrl.text.replaceAll(',', '.')) ?? 0.0;

            final double finalPriceUSD = addTax16 ? baseUSD * 1.16 : baseUSD;
            final double finalPriceBs = finalPriceUSD * widget.exchangeRate;

            void recalculateFromPackage() {
              final cost = double.tryParse(
                      costPriceCtrl.text.replaceAll(',', '.')) ??
                  0.0;
              final units = int.tryParse(unitsCtrl.text) ?? 1;
              final margin = double.tryParse(
                      marginCtrl.text.replaceAll(',', '.')) ??
                  0.0;

              if (units > 0 && cost > 0) {
                final unitCost = cost / units;
                final suggestedBase =
                    margin > 0 ? unitCost * (1 + (margin / 100)) : unitCost;

                setDialogState(() {
                  priceUsdCtrl.text = suggestedBase.toStringAsFixed(2);
                  priceBsCtrl.text =
                      (suggestedBase * widget.exchangeRate).toStringAsFixed(2);
                });
              }
            }

            final cost =
                double.tryParse(costPriceCtrl.text.replaceAll(',', '.')) ??
                    0.0;
            final units = int.tryParse(unitsCtrl.text) ?? 1;
            final unitCost = units > 0 ? (cost / units) : 0.0;

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
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
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
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Datos Básicos
                      Text(
                        'INFORMACIÓN GENERAL',
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

                      // Control de Inventario / Stock Tonal
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

                      // 2. Calculadora de Caja (Opcional)
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
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'Costo por Caja / Bulto (Calculadora Opcional)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: costPriceCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (_) => recalculateFromPackage(),
                                    decoration: customInputDecoration(
                                      label: 'Costo Caja (USD)',
                                      prefixText: r'$ ',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: unitsCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => recalculateFromPackage(),
                                    decoration: customInputDecoration(
                                      label: 'Unids en Caja',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: marginCtrl,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (_) => recalculateFromPackage(),
                                    decoration: customInputDecoration(
                                      label: '% Ganancia',
                                      suffixText: '%',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (cost > 0 && units > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '➔ Costo unitario real: \$${unitCost.toStringAsFixed(2)} por unidad',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3. Fijación de Precio de Venta (Dual USD / Bs. e IVA 16%)
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.sell_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Precio de Venta Unitario',
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
                                    'Tasa BCV: Bs. ${widget.exchangeRate.toStringAsFixed(2)}',
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
                            const SizedBox(height: 12),

                            // Inputs interactivos
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
                                        priceBsCtrl.text = (usd *
                                                widget.exchangeRate)
                                            .toStringAsFixed(2);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: 'Precio en Dólares (\$)',
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
                                        priceUsdCtrl.text = (widget
                                                        .exchangeRate >
                                                    0
                                                ? bs / widget.exchangeRate
                                                : 0.0)
                                            .toStringAsFixed(2);
                                      });
                                    },
                                    decoration: customInputDecoration(
                                      label: 'Precio en Bolívares (Bs.)',
                                      prefixText: 'Bs. ',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Selector de IVA (16%)
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
                                    value: addTax16,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        addTax16 = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'El monto ingresado es Sin IVA (Agregar +16%)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          addTax16
                                              ? 'Se sumará el 16% de IVA al precio final'
                                              : 'El precio ingresado ya es el monto final (o producto exento)',
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

                            // Resumen Final
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
                                        'PRECIO FINAL DE VENTA:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      if (addTax16)
                                        Text(
                                          'Base: \$${baseUSD.toStringAsFixed(2)} + IVA: \$${(baseUSD * 0.16).toStringAsFixed(2)}',
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
                                        '\$${finalPriceUSD.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'Bs. ${finalPriceBs.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
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

                    if (finalPriceUSD <= 0) {
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
                      price: finalPriceUSD,
                      costPrice: double.tryParse(
                              costPriceCtrl.text.replaceAll(',', '.')) ??
                          0.0,
                      unitsPerPackage: int.tryParse(unitsCtrl.text) ?? 1,
                      profitMargin: double.tryParse(
                              marginCtrl.text.replaceAll(',', '.')) ??
                          0.0,
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
