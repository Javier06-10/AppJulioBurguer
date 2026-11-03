import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Pantalla para elegir la ubicación de entrega moviendo el mapa bajo un pin fijo.
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
  late LatLng _center = widget.initial ?? LocationService.defaultCenter;
  bool _locating = false;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    // Sin ubicación guardada: intenta centrar en la posición actual
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _goToMe(silent: true),
      );
    }
  }

  Future<void> _goToMe({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final me = await _location.current();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación de entrega')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null ? 13 : 17,
              minZoom: 5,
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
                    'Mueve el mapa hasta que el pin quede en tu puerta.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                    style: t.labelSmall,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _center),
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
