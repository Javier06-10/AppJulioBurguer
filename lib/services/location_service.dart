import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'location_errors.dart';

/// Ubicación de entrega del cliente, guardada en `users/{uid}.ubicacion`.
class LocationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Centro por defecto del mapa (Santo Domingo).
  static const defaultCenter = LatLng(18.4861, -69.9312);

  static LatLng? fromMap(dynamic data) {
    if (data is! Map) return null;
    final lat = data['lat'], lng = data['lng'];
    if (lat is num && lng is num) return LatLng(lat.toDouble(), lng.toDouble());
    return null;
  }

  static Map<String, dynamic> toMap(LatLng p) => {
    'lat': p.latitude,
    'lng': p.longitude,
  };

  /// Enlace a Google Maps para un punto exacto.
  static String mapsUrl(LatLng p) =>
      'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}';

  Future<LatLng?> getSaved() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return fromMap(doc.data()?['ubicacion']);
  }

  Future<void> save(LatLng p) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const LocationException(LocationErrorKind.sinSesion);
    }
    try {
      await _db.collection('users').doc(user.uid).update({
        'ubicacion': {...toMap(p), 'updatedAt': FieldValue.serverTimestamp()},
      });
    } catch (e) {
      throw LocationException.from(e);
    }
  }

  /// Posición actual del dispositivo. Si no se puede, lanza una
  /// [LocationException] con el motivo (GPS apagado, sin permiso, sin señal…).
  Future<LatLng> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(LocationErrorKind.gpsApagado);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationErrorKind.permisoDenegado);
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(LocationErrorKind.permisoBloqueado);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      throw LocationException.from(e);
    }
  }
}
