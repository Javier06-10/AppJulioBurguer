import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_status.dart';

/// Pedido tal como lo ve el panel admin.
class AdminOrder {
  final String id;
  final String email;
  final double total;
  final OrderStatus status;
  final DateTime? createdAt;
  final int tiempoEstimado;
  final String description;
  final List<Map<String, dynamic>> items;

  AdminOrder({
    required this.id,
    required this.email,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.tiempoEstimado,
    required this.description,
    required this.items,
  });

  factory AdminOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdminOrder(
      id: doc.id,
      email: d['email']?.toString() ?? 'Cliente',
      total: (d['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromValue(d['status']?.toString()),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      tiempoEstimado: (d['tiempoEstimado'] as num?)?.toInt() ?? 0,
      description: d['description']?.toString() ?? '',
      items: (d['items'] is List)
          ? (d['items'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const [],
    );
  }

  String get shortId => '#${id.substring(0, 5).toUpperCase()}';

  int get itemCount =>
      items.fold(0, (acc, i) => acc + ((i['cantidad'] as num?)?.toInt() ?? 0));

  int get elapsedMinutes =>
      createdAt == null ? 0 : DateTime.now().difference(createdAt!).inMinutes;

  bool get isDelayed =>
      status.isActive && tiempoEstimado > 0 && elapsedMinutes > tiempoEstimado;
}

class AdminProduct {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final int tiempoPreparacion;
  final bool activo;
  final DocumentReference? categoriaRef;

  AdminProduct({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.tiempoPreparacion,
    required this.activo,
    required this.categoriaRef,
  });

  factory AdminProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final cat = d['categoriaId'];
    return AdminProduct(
      id: doc.id,
      nombre: d['nombre']?.toString() ?? '',
      descripcion: d['descripcion']?.toString() ?? '',
      precio: (d['precio'] as num?)?.toDouble() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      tiempoPreparacion: (d['tiempoPreparacion'] as num?)?.toInt() ?? 10,
      activo: d['activo'] == true,
      categoriaRef: cat is DocumentReference ? cat : null,
    );
  }
}

class AdminCategory {
  final String id;
  final String nombre;
  final bool activo;
  final DocumentReference ref;

  AdminCategory({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.ref,
  });

  factory AdminCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdminCategory(
      id: doc.id,
      nombre: d['nombre']?.toString() ?? 'Sin nombre',
      activo: d['activo'] == true,
      ref: doc.reference,
    );
  }
}

class AdminUser {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String direccion;
  final String phone;

  AdminUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.direccion,
    required this.phone,
  });

  factory AdminUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdminUser(
      id: doc.id,
      nombre: (d['name'] ?? d['nombre'] ?? 'Sin nombre').toString(),
      email: d['email']?.toString() ?? '',
      rol: d['rol']?.toString() ?? 'cliente',
      direccion: d['direccion']?.toString() ?? '',
      phone: d['phone']?.toString() ?? '',
    );
  }

  bool get isAdmin => rol == 'admin';
}

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Rol del usuario autenticado ('admin' | 'cliente').
  Future<String> getRole(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data()?['rol']?.toString() ?? 'cliente';
  }

  // ---------------- Pedidos ----------------

  Stream<List<AdminOrder>> watchOrders({int limit = 300}) => _orders
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AdminOrder.fromDoc).toList());

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _orders.doc(orderId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ---------------- Productos ----------------

  Stream<List<AdminProduct>> watchProducts() => _products.snapshots().map(
    (s) => s.docs.map(AdminProduct.fromDoc).toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      ),
  );

  Future<void> saveProduct({
    String? id,
    required String nombre,
    required String descripcion,
    required double precio,
    required int stock,
    required int tiempoPreparacion,
    required bool activo,
    required DocumentReference? categoriaRef,
  }) {
    final data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'tiempoPreparacion': tiempoPreparacion,
      'activo': activo,
      'categoriaId': categoriaRef,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      return _products.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return _products.doc(id).update(data);
  }

  Future<void> setProductActive(String id, bool activo) =>
      _products.doc(id).update({'activo': activo});

  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  // ---------------- Categorías ----------------

  Stream<List<AdminCategory>> watchCategories() => _categories.snapshots().map(
    (s) => s.docs.map(AdminCategory.fromDoc).toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      ),
  );

  Future<void> saveCategory({String? id, required String nombre}) {
    if (id == null) {
      return _categories.add({
        'nombre': nombre,
        'activo': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return _categories.doc(id).update({'nombre': nombre});
  }

  Future<void> setCategoryActive(String id, bool activo) =>
      _categories.doc(id).update({'activo': activo});

  // ---------------- Usuarios ----------------

  Stream<List<AdminUser>> watchUsers() => _users.snapshots().map(
    (s) => s.docs.map(AdminUser.fromDoc).toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      ),
  );

  Future<void> setUserRole(String uid, String rol) =>
      _users.doc(uid).update({'rol': rol});
}
