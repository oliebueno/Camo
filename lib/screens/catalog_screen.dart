import 'package:flutter/material.dart';
import '../data/mock_products.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

/// Pantalla Principal del Catálogo y Búsqueda de Productos
/// Es un StatefulWidget porque maneja estado local (búsqueda, filtros y carrito)
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Lista de todos los productos disponibles
  final List<Product> _allProducts = initialMockProducts;

  // Estado de la búsqueda y filtros
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  // Controlador para el campo de texto del buscador
  final TextEditingController _searchController = TextEditingController();

  // El carrito de compras actual: Map<idProducto, CartItem>
  // Usamos un Map para que buscar o actualizar un producto por su ID sea instantáneo O(1)
  final Map<String, CartItem> _cart = {};

  /// Obtiene la lista única de categorías disponibles para los filtros rápidos
  List<String> get _categories {
    final categories = _allProducts.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['Todos', ...categories];
  }

  /// Filtra los productos según el texto buscado y la categoría seleccionada
  List<Product> get _filteredProducts {
    return _allProducts.where((product) {
      // 1. Filtro por categoría
      final matchesCategory = _selectedCategory == 'Todos' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();

      // 2. Filtro por texto (busca por nombre o código de barras)
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Calcula el total monetario actual del carrito
  double get _cartTotal {
    return _cart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Calcula la cantidad total de artículos en el carrito
  int get _cartItemCount {
    return _cart.values.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Agrega una unidad de un producto al carrito
  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity += 1;
      } else {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  /// Resta una unidad del carrito (si llega a 0 se elimina)
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

  /// Vacía todo el carrito
  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  /// Abre la pantalla del Carrito y Calculadora de Venta
  void _openCartScreen() async {
    // Navigator.push es el equivalente a router.push() en React / Next.js
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cart: _cart,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
          onClearCart: _clearCart,
        ),
      ),
    );

    // Al regresar del carrito, refrescamos la pantalla
    setState(() {});
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
        title: const Row(
          children: [
            Icon(Icons.point_of_sale_rounded, size: 28),
            SizedBox(width: 10),
            Text(
              'Camo Precios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Botón directo para ver el carrito en el AppBar con badge de contador
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
      body: Column(
        children: [
          // 1. Buscador en tiempo real
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Cada tecla pulsada actualiza el estado (como onChange en React)
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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Filtros de Categoría horizontales (Pills)
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

          // 3. Lista de Productos (Virtualizada con ListView.builder)
          Expanded(
            child: filtered.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final quantity = _cart[product.id]?.quantity ?? 0;

                      return ProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        cartQuantity: quantity,
                        onAdd: () => _addToCart(product),
                        onRemove: () => _removeFromCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 4. Barra Inferior Flotante de Total y Venta
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
                    // Resumen de cantidad y total
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
                        Text(
                          '\$${_cartTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Botón para ir a cobrar / ver detalle
                    FilledButton.icon(
                      onPressed: _openCartScreen,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text(
                        'Cobrar / Carrito',
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
