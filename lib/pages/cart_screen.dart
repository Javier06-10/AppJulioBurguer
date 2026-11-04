import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../widgets/checkout_sheet.dart';
import '../widgets/verify_email_dialog.dart';
import '../services/store_status.dart';
import '../widgets/store_closed_banner.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController descriptionCtrl = TextEditingController();
  final OrderService orderService = OrderService();
  bool _sending = false;

  Future<void> _confirmOrder(CartProvider cart, int tiempoEstimado) async {
    if (!await ensureVerifiedEmail(context) || !mounted) return;

    final checkout = await showCheckoutSheet(context, cart.total);
    if (checkout == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await orderService.createOrder(
        items: cart.items.values.toList(),
        total: cart.total,
        tiempoEstimado: tiempoEstimado,
        description: descriptionCtrl.text.trim(),
        checkout: checkout,
      );
      cart.clear();
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Pedido enviado! Te avisaremos cuando esté listo.'),
        ),
      );
    } on OrderRejected catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      debugPrint('Error creando pedido: $e');
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo enviar el pedido. Revisa tu conexión e inténtalo de nuevo.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    /// ⏱️ Tiempo estimado total del pedido
    final int tiempoEstimado = orderService.calcularTiempoEstimado(
      cart.items.values.toList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Carrito vacío'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: cart.items.values.map((item) {
                      return ListTile(
                        title: Text(item.nombre),
                        subtitle: Text(
                          'RD\$ ${item.precio} x ${item.cantidad}\n'
                          '⏱️ ${item.tiempoPreparacion} min',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  cart.decreaseItem(item.productId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => cart.addItem(
                                item.productId,
                                item.nombre,
                                item.precio,
                                item.tiempoPreparacion,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                /// 📝 Notas del pedido
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: descriptionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas del pedido (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '⏱️ Tiempo estimado: $tiempoEstimado min',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: RD\$ ${cart.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<StoreStatus>(
                        stream: storeStatusStream(),
                        builder: (context, snap) {
                          final negocio = snap.data ?? StoreStatus.open;
                          return Column(
                            children: [
                              if (!negocio.abierto) ...[
                                StoreClosedCard(status: negocio),
                                const SizedBox(height: 12),
                              ],
                              ElevatedButton(
                                onPressed: _sending || !negocio.abierto
                                    ? null
                                    : () => _confirmOrder(cart, tiempoEstimado),
                                child: _sending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        negocio.abierto
                                            ? 'Confirmar Pedido'
                                            : 'Cerrado por ahora',
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
