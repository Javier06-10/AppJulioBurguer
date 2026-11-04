import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/checkout_data.dart';
import '../models/models/cart_item.dart';
import 'store_status.dart';

/// Límites contra pedidos falsos. Deben coincidir con las reglas de
/// Firestore (`minutosEntrePedidos` y `maxPedidosPorDia`), que son las que
/// realmente los hacen cumplir.
const minutosEntrePedidos = 5;
const maxPedidosPorDia = 5;

/// El pedido no se envió por una razón que el cliente debe conocer.
class OrderRejected implements Exception {
  final String message;
  const OrderRejected(this.message);

  @override
  String toString() => message;
}

/// Revisa el perfil del cliente antes de pedir. Devuelve el motivo por el
/// que no puede pedir ahora, o null si puede.
String? orderBlockReason(Map<String, dynamic> perfil, DateTime now) {
  if (perfil['bloqueado'] == true) {
    return 'Tu cuenta no puede hacer pedidos. Si crees que es un error, contáctanos.';
  }

  final ultimo = _date(perfil['ultimoPedido']);
  if (ultimo != null) {
    final espera =
        ultimo.add(const Duration(minutes: minutosEntrePedidos)).difference(now);
    if (espera > Duration.zero) {
      final min = (espera.inSeconds / 60).ceil();
      return 'Acabas de hacer un pedido. Podrás hacer otro en '
          '$min ${min == 1 ? 'minuto' : 'minutos'}.';
    }
  }

  final ventana = _date(perfil['ventanaInicio']);
  final count = (perfil['pedidosVentana'] as num?)?.toInt() ?? 0;
  if (ventana != null &&
      now.isBefore(ventana.add(const Duration(hours: 24))) &&
      count >= maxPedidosPorDia) {
    return 'Llegaste al máximo de $maxPedidosPorDia pedidos en 24 horas. '
        'Si necesitas más, llámanos.';
  }
  return null;
}

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

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

  /// Crea el pedido y, en la misma escritura, actualiza el registro de
  /// pedidos del cliente (las reglas exigen ambos juntos).
  Future<void> createOrder({
    required List<CartItem> items,
    required double total,
    required int tiempoEstimado,
    required String description,
    required CheckoutData checkout,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const OrderRejected('Inicia sesión para hacer tu pedido.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final orderRef = _firestore.collection('orders').doc();

    await _firestore.runTransaction((tx) async {
      final negocio = StoreStatus.fromMap(
        (await tx.get(_firestore.collection('config').doc('negocio'))).data(),
      );
      if (!negocio.abierto) {
        throw OrderRejected(
          'Estamos cerrados ahora mismo.'
          '${negocio.mensaje.isNotEmpty ? ' ${negocio.mensaje}' : ''} '
          'Tu carrito queda guardado para cuando abramos.',
        );
      }

      final snap = await tx.get(userRef);
      if (!snap.exists) {
        throw const OrderRejected(
          'Completa tu perfil antes de pedir. Cierra sesión y vuelve a entrar.',
        );
      }
      final perfil = snap.data()!;
      final reason = orderBlockReason(perfil, DateTime.now());
      if (reason != null) throw OrderRejected(reason);

      final ventana = _date(perfil['ventanaInicio']);
      final nuevaVentana = ventana == null ||
          DateTime.now().isAfter(ventana.add(const Duration(hours: 24)));

      tx.set(orderRef, {
        'userId': user.uid,
        'email': user.email,
        'items': items
            .map((item) => {
                  'productId': item.productId,
                  'nombre': item.nombre,
                  'precio': item.precio,
                  'cantidad': item.cantidad,
                  'tiempoPreparacion': item.tiempoPreparacion,
                })
            .toList(),
        'total': total,
        'tiempoEstimado': tiempoEstimado,
        'description': description,
        'entrega': checkout.entregaMap(),
        'pago': checkout.pagoMap(total),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'ultimoPedido': FieldValue.serverTimestamp(),
        'ultimoPedidoId': orderRef.id,
        if (nuevaVentana) 'ventanaInicio': FieldValue.serverTimestamp(),
        'pedidosVentana': nuevaVentana
            ? 1
            : ((perfil['pedidosVentana'] as num?)?.toInt() ?? 0) + 1,
      });
    });
  }
}
