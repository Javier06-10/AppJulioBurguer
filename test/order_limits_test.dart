import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_julioburguer/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 4, 12);
  Timestamp ago(Duration d) => Timestamp.fromDate(now.subtract(d));

  test('un cliente nuevo puede pedir', () {
    expect(orderBlockReason({}, now), isNull);
  });

  test('un cliente bloqueado no puede pedir', () {
    expect(orderBlockReason({'bloqueado': true}, now), contains('no puede hacer pedidos'));
  });

  test('debe esperar 5 minutos entre pedidos', () {
    final r = orderBlockReason({'ultimoPedido': ago(const Duration(minutes: 2))}, now);
    expect(r, contains('3 minutos'));
    expect(orderBlockReason({'ultimoPedido': ago(const Duration(minutes: 6))}, now), isNull);
  });

  test('máximo 5 pedidos en 24 horas', () {
    final perfil = {
      'ultimoPedido': ago(const Duration(hours: 1)),
      'ventanaInicio': ago(const Duration(hours: 10)),
      'pedidosVentana': 5,
    };
    expect(orderBlockReason(perfil, now), contains('máximo de 5'));
    perfil['pedidosVentana'] = 4;
    expect(orderBlockReason(perfil, now), isNull);
    // Pasadas 24 horas la cuenta vuelve a empezar
    perfil
      ..['pedidosVentana'] = 5
      ..['ventanaInicio'] = ago(const Duration(hours: 25));
    expect(orderBlockReason(perfil, now), isNull);
  });
}
