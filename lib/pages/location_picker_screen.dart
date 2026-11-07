import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/delivery_zone.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Pantalla para elegir la ubicación de entrega moviendo el mapa bajo un pin fijo.
/// El mapa no sale de la zona de delivery ([DeliveryZone]) y solo deja
/// guardar puntos dentro de ella.
/// Devuelve el [LatLng] elegido con `Navigator.pop`, o null si se cancela.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _location = LocationService();
  // Una ubicación guardada fuera de la zona no sirve: se empieza en el pueblo
  late final LatLng? _initial =
      widget.initial != null && DeliveryZone.contiene(widget.initial!)
      ? widget.initial
      : null;
  late LatLng _center = _initial ?? DeliveryZone.centro;
  bool _locating = false;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    // Sin ubicación guardada: intenta centrar en la posición actual
    if (_initial == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _goToMe(silent: true),
      );
    }
  }

  Future<void> _goToMe({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final me = await _location.current();
      if (!DeliveryZone.contiene(me)) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Estás fuera de nuestra zona de delivery '
                '(${DeliveryZone.nombre}). Mueve el mapa hasta tu puerta '
                'o recoge en el local.',
              ),
            ),
          );
        }
        return;
      }
      _map.move(me, 17);
      setState(() => _center = me);
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dentro = DeliveryZone.contiene(_center);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación de entrega')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _initial == null ? 14 : 17,
              minZoom: 12,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: DeliveryZone.limitesMapa,
              ),
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, hasGesture) {
                setState(() {
                  _center = camera.center;
                  _moving = hasGesture;
                });
              },
              onMapEvent: (e) {
                if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd) {
                  setState(() => _moving = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.djulio.app',
              ),
              // Zona de delivery
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: DeliveryZone.centro,
                    radius: DeliveryZone.radioKm * 1000,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [TextSourceAttribution('OpenStreetMap')],
              ),
            ],
          ),

          // Pin fijo en el centro: la punta marca la ubicación
          IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                offset: Offset(0, _moving ? -0.62 : -0.5),
                child: const Icon(
                  Icons.location_on,
                  size: 52,
                  color: AppColors.ember,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
            ),
          ),

          // Botón "mi ubicación"
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'me',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: _locating ? null : _goToMe,
              tooltip: 'Usar mi ubicación actual',
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Tarjeta inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                18 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('¿Dónde te entregamos?', style: t.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Mueve el mapa hasta que el pin quede en tu puerta. '
                    'Llevamos pedidos dentro del círculo: ${DeliveryZone.nombre}.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  dentro
                      ? Text(
                          '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                          style: t.labelSmall,
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.wrong_location_outlined,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Fuera de la zona de delivery',
                                style: t.bodySmall?.copyWith(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: dentro
                        ? () => Navigator.pop(context, _center)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar esta ubicación'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
