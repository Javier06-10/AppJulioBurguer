import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_julioburguer/pages/product_detail_screen.dart';
import '../widgets/bottom_nav.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductsScreen extends StatefulWidget {
  final DocumentReference categoryRef;
  final String categoryName;

  const ProductsScreen({
    super.key,
    required this.categoryRef,
    required this.categoryName,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return Scaffold(
      extendBody: true,
      floatingActionButton: const CartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade600,
                                    Colors.red.shade600,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "D'JULIO",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  widget.categoryName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // BUSCADOR
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.orange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= LISTA PRODUCTOS =================
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: productService.getProductosPorCategoria(
                    widget.categoryRef,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay productos disponibles',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    var productos = snapshot.data!;

                    if (searchQuery.isNotEmpty) {
                      productos = productos
                          .where(
                            (p) =>
                                p.nombre.toLowerCase().contains(searchQuery) ||
                                p.descripcion.toLowerCase().contains(
                                  searchQuery,
                                ),
                          )
                          .toList();
                    }

                    return ListView.builder(
                      // espacio extra para la barra inferior flotante
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 110),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        final p = productos[index];
                        final isOutOfStock = p.stock <= 0;

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: p),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white.withOpacity(0.05),
                            margin: const EdgeInsets.only(bottom: 15),
                            child: ListTile(
                              leading: const Icon(
                                Icons.fastfood,
                                color: Colors.orange,
                              ),
                              title: Text(
                                p.nombre,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                p.descripcion,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: isOutOfStock
                                  ? const Text(
                                      'Agotado',
                                      style: TextStyle(color: Colors.red),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () {
                                        Provider.of<CartProvider>(
                                          context,
                                          listen: false,
                                        ).addItem(
                                          p.id,
                                          p.nombre,
                                          p.precio,
                                          p.tiempoPreparacion,
                                        );
                                      },
                                    ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
