import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/bcv_service.dart';
import '../services/supabase_service.dart';
import '../widgets/product_card.dart';
import 'admin_screen.dart';
import 'cart_screen.dart';

/// Pantalla Principal del Catálogo para Vendedores (Conectada a Supabase y Offline-First)
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Product> _allProducts = [];
  bool _isLoadingProducts = true;

  // Estado de la búsqueda y filtros
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  // Tasa de cambio activa (Bolívares por Dólar) y fecha
  double _exchangeRate = 36.50;
  String _rateDate = 'Cargando...';
  bool _isLoadingRate = false;

  final TextEditingController _searchController = TextEditingController();
  final Map<String, CartItem> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _fetchBcvRate();
  }

  /// Carga los productos desde Supabase (o del caché local si está sin conexión)
  Future<void> _loadProducts({bool showToast = false}) async {
    setState(() => _isLoadingProducts = true);
    final products = await SupabaseService.getProducts();

    if (!mounted) return;

    setState(() {
      _allProducts = products;
      _isLoadingProducts = false;
    });

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_allProducts.length} productos sincronizados'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Consulta la tasa del BCV en segundo plano
  Future<void> _fetchBcvRate({bool showToast = false}) async {
    setState(() => _isLoadingRate = true);

    final result = await BcvService.fetchOfficialRate();

    if (!mounted) return;

    setState(() {
      _isLoadingRate = false;
      if (result.isSuccess) {
        _exchangeRate = result.rate;
        _rateDate = result.date;
      }
    });

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess
                ? '✅ Tasa BCV actualizada: Bs. ${_exchangeRate.toStringAsFixed(2)}'
                : '⚠️ No se pudo conectar al BCV, usando tasa guardada.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<String> get _categories {
    final categories = _allProducts.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['Todos', ...categories];
  }

  List<Product> get _filteredProducts {
    return _allProducts.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();

      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  double get _cartTotalUSD =>
      _cart.values.fold(0.0, (sum, item) => sum + item.subtotal);

  int get _cartTotalBsRounded => (_cartTotalUSD * _exchangeRate).round();

  int get _cartItemCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity += 1;
      } else {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        if (_cart[product.id]!.quantity > 1) {
          _cart[product.id]!.quantity -= 1;
        } else {
          _cart.remove(product.id);
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  void _editExchangeRateDialog() {
    final controller =
        TextEditingController(text: _exchangeRate.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 24),
            SizedBox(width: 8),
            Text('Tasa Oficial BCV'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tasa obtenida: Bs. ${_exchangeRate.toStringAsFixed(2)}\nFecha: $_rateDate',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajustar tasa manualmente si lo deseas:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: 'Bs. ',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _fetchBcvRate(showToast: true);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Actualizar desde BCV'),
          ),
          FilledButton(
            onPressed: () {
              final newRate =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (newRate != null && newRate > 0) {
                setState(() {
                  _exchangeRate = newRate;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _openCartScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cart: _cart,
          exchangeRate: _exchangeRate,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
          onClearCart: _clearCart,
        ),
      ),
    );

    setState(() {});
  }

  void _openAdminScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminScreen(
          exchangeRate: _exchangeRate,
          onProductsChanged: () => _loadProducts(),
        ),
      ),
    );

    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Camo Precios',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Botón Chip con la tasa oficial BCV
          ActionChip(
            avatar: _isLoadingRate
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_balance, size: 16),
            label: Text(
              _isLoadingRate
                  ? 'BCV...'
                  : 'BCV: Bs. ${_exchangeRate.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: _editExchangeRateDialog,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(width: 4),

          // Botón para entrar al Panel de Administración (Desktop / Windows)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Panel de Administración (Gestión)',
            onPressed: _openAdminScreen,
          ),

          // Botón Carrito con badge
          IconButton(
            onPressed: _openCartScreen,
            icon: Badge(
              isLabelVisible: _cartItemCount > 0,
              label: Text('$_cartItemCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sincronizando catálogo con Supabase...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadProducts(showToast: true),
              child: Column(
                children: [
                  // 1. Buscador en tiempo real
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // 2. Filtros de Categoría
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // 3. Lista de Productos
                  Expanded(
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 64,
                                        color: theme.colorScheme.outline,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No se encontraron productos',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.colorScheme.outline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              final quantity = _cart[product.id]?.quantity ?? 0;

                              return ProductCard(
                                key: ValueKey(product.id),
                                product: product,
                                cartQuantity: quantity,
                                exchangeRate: _exchangeRate,
                                onAdd: () => _addToCart(product),
                                onRemove: () => _removeFromCart(product),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

      // 4. Barra Inferior Flotante de Total Dual ($ 4 decimales y Bs. entero)
      bottomSheet: _cartItemCount > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_cartItemCount ${_cartItemCount == 1 ? "artículo" : "artículos"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${_cartTotalUSD.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bs. $_cartTotalBsRounded',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),

                    FilledButton.icon(
                      onPressed: _openCartScreen,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text(
                        'Cobrar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
