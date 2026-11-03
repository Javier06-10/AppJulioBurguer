import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../widgets/checkout_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController descriptionCtrl = TextEditingController();
  final OrderService orderService = OrderService();

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
                      ElevatedButton(
                        onPressed: () async {
                          final checkout =
                              await showCheckoutSheet(context, cart.total);
                          if (checkout == null) return;

                          await orderService.createOrder(
                            items: cart.items.values.toList(),
                            total: cart.total,
                            tiempoEstimado: tiempoEstimado,
                            description: descriptionCtrl.text.trim(),
                            checkout: checkout,
                          );

                          cart.clear();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Confirmar Pedido'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
