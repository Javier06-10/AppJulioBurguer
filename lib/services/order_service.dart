import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models/cart_item.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ⏱️ Calcula el tiempo estimado del pedido
  int calcularTiempoEstimado(List<CartItem> items) {
    if (items.isEmpty) return 0;

    return items
        .map((item) => item.tiempoPreparacion)
        .reduce((a, b) => a > b ? a : b);
  }

  /// ✅ MÉTODO CORRECTO (CON tiempoEstimado)
  Future<void> createOrder({
    required List<CartItem> items,
    required double total,
     required int tiempoEstimado,
    required String description,
   
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('orders').add({
      'userId': user.uid,
      'email': user.email,
      'items': items.map((item) => {
            'productId': item.productId,
            'nombre': item.nombre,
            'precio': item.precio,
            'cantidad': item.cantidad,
            'tiempoPreparacion': item.tiempoPreparacion,
          }).toList(),
      'total': total,
      'tiempoEstimado': tiempoEstimado,
      'description': description,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
