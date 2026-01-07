import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Método para obtener TODOS los productos activos
  Stream<List<Product>> getTodosLosProductos() {
    return _db
        .collection('products')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Product>> getProductosPorCategoria(
    DocumentReference categoryRef,
  ) {
    return _db
        .collection('products')
        .where('activo', isEqualTo: true)
        .where('categoriaId', isEqualTo: categoryRef)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }
}
