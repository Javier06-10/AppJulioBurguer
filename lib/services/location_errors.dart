import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';
import 'delivery_zone.dart';

/// Tipos de error al buscar o guardar la ubicación del cliente.
enum LocationErrorKind {
  /// El GPS / servicio de ubicación del dispositivo está apagado.
  gpsApagado,

  /// El cliente dijo que no al permiso (se puede volver a pedir).
  permisoDenegado,

  /// El permiso quedó bloqueado: hay que activarlo en los ajustes.
  permisoBloqueado,

  /// El GPS no respondió a tiempo (señal débil, bajo techo…).
  sinSenal,

  /// La ubicación está fuera de la zona de delivery.
  fueraDeZona,

  /// No hay sesión iniciada.
  sinSesion,

  /// Sin internet al guardar.
  sinConexion,

  /// Cualquier otro fallo.
  desconocido,
}

/// Error de ubicación con un mensaje claro para el cliente.
class LocationException implements Exception {
  final LocationErrorKind kind;
  const LocationException(this.kind);

  String get titulo => switch (kind) {
    LocationErrorKind.gpsApagado => 'La ubicación está apagada',
    LocationErrorKind.permisoDenegado => 'Necesitamos tu permiso',
    LocationErrorKind.permisoBloqueado => 'El permiso de ubicación está bloqueado',
    LocationErrorKind.sinSenal => 'No pudimos encontrarte',
    LocationErrorKind.fueraDeZona => 'Estás fuera de nuestra zona',
    LocationErrorKind.sinSesion => 'Inicia sesión',
    LocationErrorKind.sinConexion => 'Sin conexión',
    LocationErrorKind.desconocido => 'Algo salió mal',
  };

  String get mensaje => switch (kind) {
    LocationErrorKind.gpsApagado =>
      'Enciende la ubicación (GPS) de tu teléfono y vuelve a tocar '
          '"Usar mi ubicación". También puedes mover el mapa hasta tu puerta.',
    LocationErrorKind.permisoDenegado =>
      'Para encontrarte en el mapa, toca "Permitir" cuando te lo pidamos. '
          'Si prefieres, mueve el mapa tú mismo hasta tu puerta.',
    LocationErrorKind.permisoBloqueado => kIsWeb
        ? 'Tu navegador tiene bloqueada la ubicación para esta página. Toca el '
              'candado junto a la dirección web, permite "Ubicación" y recarga. '
              'O mueve el mapa hasta tu puerta.'
        : 'Activa el permiso de ubicación para D\'Julio en los ajustes del '
              'teléfono, o mueve el mapa hasta tu puerta.',
    LocationErrorKind.sinSenal =>
      'El GPS tardó demasiado. Sal a un lugar abierto o cerca de una ventana '
          'e inténtalo otra vez, o mueve el mapa hasta tu puerta.',
    LocationErrorKind.fueraDeZona =>
      'Solo llevamos pedidos dentro de ${DeliveryZone.nombre}. Si estás en otro '
          'lugar ahora, mueve el mapa hasta donde quieres recibirlo o elige '
          'recoger en el local.',
    LocationErrorKind.sinSesion =>
      'Inicia sesión para guardar tu ubicación de entrega.',
    LocationErrorKind.sinConexion =>
      'No pudimos guardar tu ubicación. Revisa tu internet e inténtalo de nuevo.',
    LocationErrorKind.desconocido =>
      'No pudimos usar tu ubicación ahora. Inténtalo de nuevo o mueve el mapa '
          'hasta tu puerta.',
  };

  IconData get icono => switch (kind) {
    LocationErrorKind.gpsApagado => Icons.location_disabled_rounded,
    LocationErrorKind.permisoDenegado ||
    LocationErrorKind.permisoBloqueado => Icons.lock_outline_rounded,
    LocationErrorKind.sinSenal => Icons.gps_not_fixed_rounded,
    LocationErrorKind.fueraDeZona => Icons.wrong_location_outlined,
    LocationErrorKind.sinSesion => Icons.person_outline_rounded,
    LocationErrorKind.sinConexion => Icons.wifi_off_rounded,
    LocationErrorKind.desconocido => Icons.error_outline_rounded,
  };

  /// Botón para arreglarlo (solo en el teléfono, el navegador no lo permite).
  String? get accion => kIsWeb
      ? null
      : switch (kind) {
          LocationErrorKind.gpsApagado => 'Encender ubicación',
          LocationErrorKind.permisoBloqueado => 'Abrir ajustes',
          _ => null,
        };

  Future<void> resolver() async {
    switch (kind) {
      case LocationErrorKind.gpsApagado:
        await Geolocator.openLocationSettings();
      case LocationErrorKind.permisoBloqueado:
        await Geolocator.openAppSettings();
      default:
        break;
    }
  }

  /// Convierte cualquier error (GPS, permisos, Firestore…) en uno legible.
  static LocationException from(Object e) {
    if (e is LocationException) return e;
    if (e is LocationServiceDisabledException) {
      return const LocationException(LocationErrorKind.gpsApagado);
    }
    if (e is PermissionDeniedException) {
      return const LocationException(LocationErrorKind.permisoDenegado);
    }
    if (e is TimeoutException || e is PositionUpdateException) {
      return const LocationException(LocationErrorKind.sinSenal);
    }
    if (e is FirebaseException) {
      return LocationException(
        e.code == 'unavailable' || e.code == 'deadline-exceeded'
            ? LocationErrorKind.sinConexion
            : e.code == 'unauthenticated' || e.code == 'permission-denied'
            ? LocationErrorKind.sinSesion
            : LocationErrorKind.desconocido,
      );
    }
    debugPrint('Ubicación: error sin clasificar (${e.runtimeType}): $e');
    return const LocationException(LocationErrorKind.desconocido);
  }

  @override
  String toString() => mensaje;
}

/// Muestra el error de ubicación en un diálogo claro, con botón para
/// arreglarlo cuando se puede.
Future<void> showLocationError(BuildContext context, Object error) {
  final e = LocationException.from(error);
  final accion = e.accion;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(e.icono, color: AppColors.warning, size: 36),
      title: Text(e.titulo, textAlign: TextAlign.center),
      content: Text(e.mensaje, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(accion == null ? 'Entendido' : 'Ahora no'),
        ),
        if (accion != null)
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              e.resolver();
            },
            child: Text(accion),
          ),
      ],
    ),
  );
}
