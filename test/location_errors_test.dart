import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_julioburguer/services/location_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Clasificación de errores de ubicación', () {
    LocationErrorKind kind(Object e) => LocationException.from(e).kind;

    test('GPS apagado', () {
      expect(kind(const LocationServiceDisabledException()),
          LocationErrorKind.gpsApagado);
    });

    test('permiso denegado', () {
      expect(kind(const PermissionDeniedException('no')),
          LocationErrorKind.permisoDenegado);
    });

    test('el GPS no responde a tiempo', () {
      expect(kind(TimeoutException('lento')), LocationErrorKind.sinSenal);
    });

    test('sin internet al guardar', () {
      expect(kind(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')),
          LocationErrorKind.sinConexion);
    });

    test('error raro: mensaje genérico, sin texto técnico', () {
      final e = LocationException.from(Exception('PlatformException(xyz)'));
      expect(e.kind, LocationErrorKind.desconocido);
      expect(e.mensaje.contains('Exception'), isFalse);
    });

    test('cada tipo tiene título y mensaje', () {
      for (final k in LocationErrorKind.values) {
        final e = LocationException(k);
        expect(e.titulo, isNotEmpty);
        expect(e.mensaje.length, greaterThan(20));
      }
    });
  });

  testWidgets('el diálogo muestra el error de forma legible', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showLocationError(
            context,
            const LocationServiceDisabledException(),
          ),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('La ubicación está apagada'), findsOneWidget);
    expect(find.textContaining('Enciende la ubicación'), findsOneWidget);
  });
}
