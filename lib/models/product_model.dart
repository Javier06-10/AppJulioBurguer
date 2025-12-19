import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final int tiempoPreparacion;

  final bool activo;
  final DocumentReference categoriaId;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.activo,
    required this.categoriaId,
    required this.tiempoPreparacion,
  });

  factory Product.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return Product(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      activo: data['activo'] ?? false,
      categoriaId: data['categoriaId'],
      tiempoPreparacion: data['tiempoPreparacion'] ?? 10,

    );
  }
}
