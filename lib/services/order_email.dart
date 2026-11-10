import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Dirección del panel, que es quien envía los correos.
/// Se define al compilar: `flutter build web --dart-define=PANEL_URL=https://...`
/// (en Vercel, con la variable de entorno PANEL_URL; ver build-web.sh).
const panelUrl = String.fromEnvironment('PANEL_URL');

/// Pide al panel que envíe al cliente un correo con el detalle de su pedido.
/// No bloquea ni falla el pedido: si el correo no sale, solo se registra.
Future<void> sendOrderEmail(String orderId) async {
  if (panelUrl.isEmpty) return;
  try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;
    final res = await http
        .post(
          Uri.parse('$panelUrl/api/recibo'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'orderId': orderId}),
        )
        // El panel gratuito puede tardar en despertar
        .timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      debugPrint('Correo del pedido no enviado (${res.statusCode}): ${res.body}');
    }
  } catch (e) {
    debugPrint('Correo del pedido no enviado: $e');
  }
}
