import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.nombre),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen/Icono
            Center(
              child: Icon(
                Icons.fastfood,
                size: 120,
                color: Colors.orange.shade600,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              product.nombre,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              product.descripcion,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'RD\$ ${product.precio.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade600,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: const EdgeInsets.all(15),
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text(
                  'Agregar al carrito',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  cart.addItem(
                    product.id,
                    product.nombre,
                    product.precio,
                    product.tiempoPreparacion,
                  );

                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
