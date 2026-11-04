import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_julioburguer/widgets/google_sign_in_button.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Future<bool> Function() signIn) {
  return tester.pumpWidget(
    MaterialApp(
      routes: {'/products': (_) => const Scaffold(body: Text('MENU'))},
      home: Scaffold(body: GoogleSignInButton(signIn: signIn)),
    ),
  );
}

void main() {
  testWidgets('al entrar con Google va al menú', (tester) async {
    await _pump(tester, () async => true);
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);
  });

  testWidgets('si cierra la ventana de Google se queda en la pantalla',
      (tester) async {
    await _pump(tester, () async => false);
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsNothing);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('un error muestra un mensaje claro', (tester) async {
    await _pump(tester, () async {
      throw FirebaseAuthException(code: 'popup-blocked');
    });
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('bloqueó la ventana de Google'), findsOneWidget);
    expect(find.text('MENU'), findsNothing);
  });
}
