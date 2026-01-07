import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProgressService {

   bool isOrderDelayed({
    required Timestamp createdAt,
    required int tiempoEstimado,
  }) {
    final startTime = createdAt.toDate();
    final expectedEnd =
        startTime.add(Duration(minutes: tiempoEstimado));

    return DateTime.now().isAfter(expectedEnd);
  }

  double calcularProgreso({
    required Timestamp createdAt,
    required int tiempoEstimado,
  }) {
    final now = DateTime.now();
    final inicio = createdAt.toDate();

    final minutosTranscurridos =
        now.difference(inicio).inMinutes;

    if (tiempoEstimado <= 0) return 0;

    return (minutosTranscurridos / tiempoEstimado)
        .clamp(0.0, 1.5);
  }

  int minutosRestantes({
    required Timestamp createdAt,
    required int tiempoEstimado,
  }) {
    final now = DateTime.now();
    final inicio = createdAt.toDate();

    final transcurridos =
        now.difference(inicio).inMinutes;

    return tiempoEstimado - transcurridos;
  }

   /// ⏱️ Minutos transcurridos desde que se creó
  int elapsedMinutes(Timestamp createdAt) {
    final diff =
        DateTime.now().difference(createdAt.toDate());
    return diff.inMinutes;
  }

}
