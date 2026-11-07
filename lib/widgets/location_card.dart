import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../pages/location_picker_screen.dart';
import '../services/delivery_zone.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Tarjeta con la ubicación de entrega del cliente: mini mapa + botón para
/// elegirla en el mapa. Al elegir, la guarda en el perfil y avisa con [onChanged].
class LocationCard extends StatefulWidget {
  final LatLng? location;
  final ValueChanged<LatLng>? onChanged;

  const LocationCard({super.key, required this.location, this.onChanged});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  bool _saving = false;

  Future<void> _pick() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: widget.location),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await LocationService().save(picked);
      widget.onChanged?.call(picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación de entrega guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo guardar: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loc = widget.location;
    final fuera = loc != null && !DeliveryZone.contiene(loc);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loc != null)
            SizedBox(
              height: 140,
              child: FlutterMap(
                // La clave hace que el mapa se recentre al cambiar la ubicación
                key: ValueKey(loc),
                options: MapOptions(
                  initialCenter: loc,
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.djulio.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: loc,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: AppColors.ember,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  loc == null
                      ? Icons.add_location_alt_outlined
                      : fuera
                      ? Icons.wrong_location_outlined
                      : Icons.place,
                  color: loc == null
                      ? AppColors.textMuted
                      : fuera
                      ? Colors.redAccent
                      : AppColors.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc == null
                            ? 'Sin ubicación en el mapa'
                            : fuera
                            ? 'Fuera de la zona de delivery'
                            : 'Ubicación de entrega guardada',
                        style: t.titleMedium,
                      ),
                      Text(
                        loc == null
                            ? 'Marca tu puerta para que el delivery llegue sin perderse'
                            : fuera
                            ? 'Solo entregamos en ${DeliveryZone.nombre}'
                            : 'El repartidor verá este punto exacto',
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _pick,
                        child: Text(loc == null ? 'Elegir' : 'Cambiar'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
