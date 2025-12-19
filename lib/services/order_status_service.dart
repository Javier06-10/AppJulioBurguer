import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusService {
  String calcularEstado(
    Timestamp createdAt,
    Timestamp horaEntregaEstimada,
  ) {
    final now = DateTime.now();

    if (now.isAfter(horaEntregaEstimada.toDate())) {
      return 'retrasado';
    }

    final minutosPasados =
        now.difference(createdAt.toDate()).inMinutes;

    if (minutosPasados < 5) {
      return 'pendiente';
    }

    return 'preparando';
  }
}
