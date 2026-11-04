import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final int tiempoPreparacion;

  final bool activo;
  final DocumentReference? categoriaId;
  final String imagen;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.activo,
    required this.categoriaId,
    required this.tiempoPreparacion,
    this.imagen = '',
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
      stock: ((data['stock'] ?? 0) as num).toInt(),
      activo: data['activo'] ?? false,
      categoriaId: data['categoriaId'] is DocumentReference
          ? data['categoriaId'] as DocumentReference
          : null,
      tiempoPreparacion: ((data['tiempoPreparacion'] ?? 10) as num).toInt(),
      imagen: (data['imagen'] ?? '').toString().trim(),

    );
  }
}
