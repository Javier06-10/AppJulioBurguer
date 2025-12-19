import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot order;

  const OrderDetailScreen({super.key, required this.order});

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = order.data() as Map<String, dynamic>;

    final String status = data['status'] ?? 'pending';
    final double total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final Timestamp? createdAt = data['createdAt'];
    final description = data['description']?.toString();
    

    final List items =
        data['items'] is List ? data['items'] as List : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del pedido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔖 ESTADO
            Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor(status),
            ),

            const SizedBox(height: 10),

            // 💰 TOTAL
            Text(
              'Total: RD\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // 📅 FECHA
            if (createdAt != null)
              Text(
                'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())}',
                
                style: TextStyle(color: Colors.grey.shade600),

              ),
if (description != null && description.isNotEmpty) ...[
  const SizedBox(height: 12),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.note_alt, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  ),
],

            const Divider(height: 30),

            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 🛒 LISTA DE PRODUCTOS
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Este pedido no tiene productos'),
                    )
                  : ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final Map item = items[index] as Map;

    final String name =
        item['nombre']?.toString() ?? 'Producto sin nombre';

    final double price =
        (item['precio'] as num?)?.toDouble() ?? 0.0;

    final int quantity =
        (item['cantidad'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          'RD\$ ${price.toStringAsFixed(2)} x $quantity',
        ),
        trailing: Text(
          'RD\$ ${(price * quantity).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  },

)



            ),
          ],
        ),
      ),
    );
  }
}
