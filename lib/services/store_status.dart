import 'package:cloud_firestore/cloud_firestore.dart';

/// Si el negocio está abierto o cerrado (lo cambia el admin desde el panel).
class StoreStatus {
  final bool abierto;

  /// Aviso para el cliente mientras está cerrado (ej. "Abrimos a las 5:00 pm").
  final String mensaje;

  const StoreStatus({required this.abierto, this.mensaje = ''});

  /// Sin configurar se considera abierto (igual que en las reglas).
  static const open = StoreStatus(abierto: true);

  factory StoreStatus.fromMap(Map<String, dynamic>? d) => StoreStatus(
    abierto: d?['abierto'] != false,
    mensaje: (d?['mensaje'] as String?)?.trim() ?? '',
  );
}

DocumentReference<Map<String, dynamic>> get _ref =>
    FirebaseFirestore.instance.collection('config').doc('negocio');

Stream<StoreStatus> storeStatusStream() =>
    _ref.snapshots().map((s) => StoreStatus.fromMap(s.data()));
