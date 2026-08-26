import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Pantalla del Carrito y Calculadora de Cobro para el Vendedor
class CartScreen extends StatefulWidget {
  final Map<String, CartItem> cart;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final VoidCallback onClearCart;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onClearCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Controlador para el efectivo recibido del cliente
  final TextEditingController _cashReceivedController = TextEditingController();
  double _cashReceived = 0.0;

  // Opción de IVA / Impuesto (ejemplo: 16% o 0%)
  bool _applyTax = false;
  final double _taxRate = 0.16; // 16%

  // Descuento en porcentaje (0% por defecto)
  double _discountPercent = 0.0;

  /// Subtotal bruto
  double get _subtotal {
    return widget.cart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Monto de descuento
  double get _discountAmount {
    return _subtotal * (_discountPercent / 100);
  }

  /// Monto de impuesto (IVA)
  double get _taxAmount {
    final base = _subtotal - _discountAmount;
    return _applyTax ? base * _taxRate : 0.0;
  }

  /// Total neto a cobrar
  double get _totalToPay {
    return (_subtotal - _discountAmount) + _taxAmount;
  }

  /// Cambio / Vuelto a entregar al cliente
  double get _changeToReturn {
    if (_cashReceived <= 0) return 0.0;
    final change = _cashReceived - _totalToPay;
    return change > 0 ? change : 0.0;
  }

  /// Monto restante que falta pagar si el efectivo no alcanza
  double get _missingAmount {
    if (_cashReceived <= 0) return 0.0;
    final diff = _totalToPay - _cashReceived;
    return diff > 0 ? diff : 0.0;
  }

  /// Genera un resumen en texto para compartir por WhatsApp
  void _shareReceipt() {
    final buffer = StringBuffer();
    buffer.writeln('🧾 *RESUMEN DE VENTA - CAMO*');
    buffer.writeln('--------------------------------');
    for (final item in widget.cart.values) {
      buffer.writeln(
          '• ${item.quantity}x ${item.product.name} @ \$${item.product.price.toStringAsFixed(2)} = \$${item.subtotal.toStringAsFixed(2)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: \$${_subtotal.toStringAsFixed(2)}');
    if (_discountPercent > 0) {
      buffer.writeln('Descuento (${_discountPercent.toInt()}%): -\$${_discountAmount.toStringAsFixed(2)}');
    }
    if (_applyTax) {
      buffer.writeln('IVA (${(_taxRate * 100).toInt()}%): +\$${_taxAmount.toStringAsFixed(2)}');
    }
    buffer.writeln('*TOTAL: \$${_totalToPay.toStringAsFixed(2)}*');
    if (_cashReceived > 0) {
      buffer.writeln('Efectivo recibido: \$${_cashReceived.toStringAsFixed(2)}');
      buffer.writeln('Cambio entregado: \$${_changeToReturn.toStringAsFixed(2)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('¡Gracias por su compra!');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Resumen copiado al portapapeles (listo para WhatsApp)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Diálogo para confirmar vaciar el carrito
  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar la venta actual?'),
        content: const Text('Se eliminarán todos los productos seleccionados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              widget.onClearCart();
              Navigator.pop(context);
              setState(() {});
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.cart.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calculadora de Venta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (items.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Copiar ticket',
              onPressed: _shareReceipt,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Vaciar carrito',
              onPressed: _confirmClearCart,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 70,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos en la venta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Regresar al Catálogo'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Lista de productos en el carrito
                  Text(
                    'Productos (${items.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...items.map((item) => _buildCartItemTile(item, theme)),

                  const SizedBox(height: 20),

                  // 2. Desglose Financiero (Subtotal, Descuentos, IVA, Total)
                  _buildFinancialBreakdown(theme),

                  const SizedBox(height: 20),

                  // 3. Calculadora de Cambio / Vuelto en Efectivo
                  _buildCashChangeCalculator(theme),

                  const SizedBox(height: 24),

                  // 4. Botón de Nueva Venta / Completar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareReceipt,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copiar Ticket'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            widget.onClearCart();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Nueva Venta'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  /// Tarjeta de cada artículo en la lista de compra
  Widget _buildCartItemTile(CartItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Controles de cantidad
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    widget.onRemoveFromCart(item.product);
                    setState(() {});
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  color: theme.colorScheme.primary,
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onAddToCart(item.product);
                    setState(() {});
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Subtotal del item
            SizedBox(
              width: 65,
              child: Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Desglose numérico con subtotal, impuesto y total
  Widget _buildFinancialBreakdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          _buildRowDetail('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),

          // Selector de Descuento rápido (0%, 5%, 10%, 15%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Descuento:', style: TextStyle(fontSize: 13)),
              Wrap(
                spacing: 4,
                children: [0.0, 5.0, 10.0, 15.0].map((pct) {
                  final isSel = _discountPercent == pct;
                  return ChoiceChip(
                    label: Text('${pct.toInt()}%'),
                    selected: isSel,
                    onSelected: (val) {
                      setState(() {
                        _discountPercent = val ? pct : 0.0;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ),
          if (_discountPercent > 0) ...[
            const SizedBox(height: 4),
            _buildRowDetail(
              'Ahorro (${_discountPercent.toInt()}%)',
              '-\$${_discountAmount.toStringAsFixed(2)}',
              color: Colors.green.shade700,
            ),
          ],

          const SizedBox(height: 6),

          // Switch de IVA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aplicar IVA (16%):', style: TextStyle(fontSize: 13)),
              Switch(
                value: _applyTax,
                onChanged: (val) {
                  setState(() {
                    _applyTax = val;
                  });
                },
              ),
            ],
          ),
          if (_applyTax) ...[
            _buildRowDetail('IVA (16%)', '+\$${_taxAmount.toStringAsFixed(2)}'),
          ],

          const Divider(height: 20),

          // Total a pagar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL A COBRAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '\$${_totalToPay.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculadora de efectivo y vuelto
  Widget _buildCashChangeCalculator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Calculadora de Cambio / Vuelto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input de dinero recibido
          TextField(
            controller: _cashReceivedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              setState(() {
                _cashReceived = double.tryParse(val) ?? 0.0;
              });
            },
            decoration: InputDecoration(
              labelText: '¿Con cuánto paga el cliente?',
              prefixText: '\$ ',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Botones de billetes rápidos ($5, $10, $20, $50, $100, Exacto)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Exacto'),
                  onPressed: () {
                    setState(() {
                      _cashReceived = _totalToPay;
                      _cashReceivedController.text = _totalToPay.toStringAsFixed(2);
                    });
                  },
                ),
                const SizedBox(width: 6),
                ...[5, 10, 20, 50, 100].map((bill) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('\$$bill'),
                      onPressed: () {
                        setState(() {
                          _cashReceived = bill.toDouble();
                          _cashReceivedController.text = '$bill';
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Resultado del Cambio / Falta
          if (_cashReceived > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _missingAmount > 0
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _missingAmount > 0
                      ? Colors.red.shade300
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _missingAmount > 0 ? 'Faltante:' : 'Cambio / Vuelto:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _missingAmount > 0
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                    ),
                  ),
                  Text(
                    _missingAmount > 0
                        ? '-\$${_missingAmount.toStringAsFixed(2)}'
                        : '\$${_changeToReturn.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: _missingAmount > 0
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String title, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
