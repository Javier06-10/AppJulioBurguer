import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
      throw Exception('Inicia sesión para guardar tu ubicación');
    }
    await _db.collection('users').doc(user.uid).update({
      'ubicacion': {...toMap(p), 'updatedAt': FieldValue.serverTimestamp()},
    });
  }

  /// Posición actual del dispositivo. Lanza un mensaje legible si no se puede.
  Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Activa la ubicación (GPS) de tu dispositivo');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Necesitamos permiso de ubicación para encontrarte');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está bloqueado. Actívalo en los ajustes del navegador o del teléfono',
      );
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  }
}
