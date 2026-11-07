import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Cargo fijo del delivery (RD$). Debe coincidir con `costoDelivery()` en
/// firestore.rules, que es quien lo hace cumplir.
const costoDelivery = 50.0;

/// Zona donde llevamos pedidos: San José de los Llanos (San Pedro de
/// Macorís, República Dominicana). Es un círculo de [radioKm] alrededor del
/// centro del pueblo. Si cambias estos valores, cambia también
/// `enZonaDelivery()` en firestore.rules.
class DeliveryZone {
  static const nombre = 'San José de los Llanos';
  static const centro = LatLng(18.6206, -69.4956);
  static const radioKm = 4.0;

  /// Radio en grados (4 km): 1° de latitud ≈ 111.32 km; 1° de longitud a
  /// esta latitud ≈ 105.5 km.
  static const _dLat = 0.0359;
  static const _dLng = 0.0379;

  /// true si el punto cae dentro de la zona de entrega.
  static bool contiene(LatLng p) {
    final a = (p.latitude - centro.latitude) / _dLat;
    final b = (p.longitude - centro.longitude) / _dLng;
    return a * a + b * b <= 1;
  }

  /// Hasta dónde se puede mover el mapa (un poco más que la zona).
  static LatLngBounds get limitesMapa => LatLngBounds(
    LatLng(centro.latitude - _dLat * 1.6, centro.longitude - _dLng * 1.6),
    LatLng(centro.latitude + _dLat * 1.6, centro.longitude + _dLng * 1.6),
  );
}
