import 'package:flutter/material.dart';
import 'package:flutter_julioburguer/services/store_status.dart';
import 'package:flutter_julioburguer/widgets/store_closed_banner.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, StoreStatus s) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: StoreClosedBanner(stream: Stream.value(s))),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('abierto: no muestra aviso', (tester) async {
    await _pump(tester, StoreStatus.open);
    expect(find.text('Estamos cerrados'), findsNothing);
  });

  testWidgets('cerrado: muestra el aviso con el mensaje del negocio',
      (tester) async {
    await _pump(
      tester,
      const StoreStatus(abierto: false, mensaje: 'Abrimos hoy a las 5:00 pm'),
    );
    expect(find.text('Estamos cerrados'), findsOneWidget);
    expect(find.text('Abrimos hoy a las 5:00 pm'), findsOneWidget);
  });

  test('sin configurar se considera abierto', () {
    expect(StoreStatus.fromMap(null).abierto, isTrue);
    expect(StoreStatus.fromMap({'abierto': false}).abierto, isFalse);
  });
}
