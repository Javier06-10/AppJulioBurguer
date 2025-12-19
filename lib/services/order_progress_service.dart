import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProgressService {
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
}
