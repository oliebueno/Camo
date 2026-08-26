import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Pantalla del Carrito y Calculadora de Cobro con soporte Bimonetario ($ y Bs.)
class CartScreen extends StatefulWidget {
  final Map<String, CartItem> cart;
  final double exchangeRate;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final VoidCallback onClearCart;

  const CartScreen({
    super.key,
    required this.cart,
    required this.exchangeRate,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onClearCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Moneda en la que el cliente paga en efectivo ('USD' o 'BS')
  String _paymentCurrency = 'USD';

  // Controlador para el monto recibido
  final TextEditingController _cashReceivedController = TextEditingController();
  double _cashReceived = 0.0;

  // IVA (16% o 0%)
  bool _applyTax = false;
  final double _taxRate = 0.16;

  // Descuento en %
  double _discountPercent = 0.0;

  // Cálculos en USD
  double get _subtotalUSD =>
      widget.cart.values.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _discountAmountUSD => _subtotalUSD * (_discountPercent / 100);

  double get _taxAmountUSD {
    final base = _subtotalUSD - _discountAmountUSD;
    return _applyTax ? base * _taxRate : 0.0;
  }

  double get _totalToPayUSD => (_subtotalUSD - _discountAmountUSD) + _taxAmountUSD;

  // Cálculos equivalentes en Bolívares (Bs.)
  double get _subtotalBs => _subtotalUSD * widget.exchangeRate;
  double get _discountAmountBs => _discountAmountUSD * widget.exchangeRate;
  double get _taxAmountBs => _taxAmountUSD * widget.exchangeRate;
  double get _totalToPayBs => _totalToPayUSD * widget.exchangeRate;

  // Cálculo de cambio / faltante según la moneda seleccionada
  double get _totalRequiredInSelectedCurrency =>
      _paymentCurrency == 'USD' ? _totalToPayUSD : _totalToPayBs;

  double get _changeToReturnInSelectedCurrency {
    if (_cashReceived <= 0) return 0.0;
    final diff = _cashReceived - _totalRequiredInSelectedCurrency;
    return diff > 0 ? diff : 0.0;
  }

  double get _missingAmountInSelectedCurrency {
    if (_cashReceived <= 0) return 0.0;
    final diff = _totalRequiredInSelectedCurrency - _cashReceived;
    return diff > 0 ? diff : 0.0;
  }

  /// Genera un resumen completo en texto para compartir por WhatsApp
  void _shareReceipt() {
    final buffer = StringBuffer();
    buffer.writeln('🧾 *RESUMEN DE VENTA - CAMO*');
    buffer.writeln('💱 Tasa del día: Bs. ${widget.exchangeRate.toStringAsFixed(2)}');
    buffer.writeln('--------------------------------');
    for (final item in widget.cart.values) {
      final itemBs = item.subtotal * widget.exchangeRate;
      buffer.writeln(
          '• ${item.quantity}x ${item.product.name}\n  \$${item.subtotal.toStringAsFixed(2)}  (Bs. ${itemBs.toStringAsFixed(2)})');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: \$${_subtotalUSD.toStringAsFixed(2)} (Bs. ${_subtotalBs.toStringAsFixed(2)})');
    if (_discountPercent > 0) {
      buffer.writeln(
          'Descuento (${_discountPercent.toInt()}%): -\$${_discountAmountUSD.toStringAsFixed(2)} (-Bs. ${_discountAmountBs.toStringAsFixed(2)})');
    }
    if (_applyTax) {
      buffer.writeln(
          'IVA (${(_taxRate * 100).toInt()}%): +\$${_taxAmountUSD.toStringAsFixed(2)} (+Bs. ${_taxAmountBs.toStringAsFixed(2)})');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('*TOTAL USD: \$${_totalToPayUSD.toStringAsFixed(2)}*');
    buffer.writeln('*TOTAL BS: Bs. ${_totalToPayBs.toStringAsFixed(2)}*');
    if (_cashReceived > 0) {
      final curSymbol = _paymentCurrency == 'USD' ? '\$' : 'Bs. ';
      buffer.writeln('Pago recibido: $curSymbol${_cashReceived.toStringAsFixed(2)}');
      buffer.writeln('Cambio entregado: $curSymbol${_changeToReturnInSelectedCurrency.toStringAsFixed(2)}');
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
                  // 1. Lista de productos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Productos (${items.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tasa: Bs. ${widget.exchangeRate.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...items.map((item) => _buildCartItemTile(item, theme)),

                  const SizedBox(height: 20),

                  // 2. Desglose Financiero Bimonetario
                  _buildFinancialBreakdown(theme),

                  const SizedBox(height: 20),

                  // 3. Calculadora de Cambio / Vuelto
                  _buildCashChangeCalculator(theme),

                  const SizedBox(height: 24),

                  // 4. Botones de Acción
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

  Widget _buildCartItemTile(CartItem item, ThemeData theme) {
    final itemBs = item.subtotal * widget.exchangeRate;

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
                    '\$${item.product.price.toStringAsFixed(2)} (Bs. ${(item.product.price * widget.exchangeRate).toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

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

            SizedBox(
              width: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Bs. ${itemBs.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          _buildDualRowDetail(
            'Subtotal',
            '\$${_subtotalUSD.toStringAsFixed(2)}',
            'Bs. ${_subtotalBs.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),

          // Selector de Descuento
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
            const SizedBox(height: 6),
            _buildDualRowDetail(
              'Ahorro (${_discountPercent.toInt()}%)',
              '-\$${_discountAmountUSD.toStringAsFixed(2)}',
              '-Bs. ${_discountAmountBs.toStringAsFixed(2)}',
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
            _buildDualRowDetail(
              'IVA (16%)',
              '+\$${_taxAmountUSD.toStringAsFixed(2)}',
              '+Bs. ${_taxAmountBs.toStringAsFixed(2)}',
            ),
          ],

          const Divider(height: 20),

          // Total a pagar Dual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TOTAL A COBRAR',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_totalToPayUSD.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Bs. ${_totalToPayBs.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashChangeCalculator(ThemeData theme) {
    final curSymbol = _paymentCurrency == 'USD' ? '\$ ' : 'Bs. ';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Calculadora de Vuelto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              // Selector de moneda de pago (USD o Bolívares)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'USD', label: Text('\$ USD')),
                  ButtonSegment(value: 'BS', label: Text('Bs.')),
                ],
                selected: {_paymentCurrency},
                onSelectionChanged: (val) {
                  setState(() {
                    _paymentCurrency = val.first;
                    _cashReceived = 0.0;
                    _cashReceivedController.clear();
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _cashReceivedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              setState(() {
                _cashReceived = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
              });
            },
            decoration: InputDecoration(
              labelText: 'Monto recibido del cliente ($_paymentCurrency)',
              prefixText: curSymbol,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Botones rápidos según moneda
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Exacto'),
                  onPressed: () {
                    final exact = _totalRequiredInSelectedCurrency;
                    setState(() {
                      _cashReceived = exact;
                      _cashReceivedController.text = exact.toStringAsFixed(2);
                    });
                  },
                ),
                const SizedBox(width: 6),
                ...(_paymentCurrency == 'USD'
                        ? [5, 10, 20, 50, 100]
                        : [100, 200, 500, 1000, 2000])
                    .map((val) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('$curSymbol$val'),
                      onPressed: () {
                        setState(() {
                          _cashReceived = val.toDouble();
                          _cashReceivedController.text = '$val';
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (_cashReceived > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _missingAmountInSelectedCurrency > 0
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _missingAmountInSelectedCurrency > 0
                      ? Colors.red.shade300
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _missingAmountInSelectedCurrency > 0
                        ? 'Faltante:'
                        : 'Cambio / Vuelto:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _missingAmountInSelectedCurrency > 0
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                    ),
                  ),
                  Text(
                    _missingAmountInSelectedCurrency > 0
                        ? '-$curSymbol${_missingAmountInSelectedCurrency.toStringAsFixed(2)}'
                        : '$curSymbol${_changeToReturnInSelectedCurrency.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: _missingAmountInSelectedCurrency > 0
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

  Widget _buildDualRowDetail(String title, String usdValue, String bsValue,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              usdValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              bsValue,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color ?? Colors.green.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
