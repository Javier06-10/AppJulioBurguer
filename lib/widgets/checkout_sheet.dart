import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:latlong2/latlong.dart';

import '../models/checkout_data.dart';
import '../services/delivery_zone.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'location_card.dart';

/// Abre la hoja de confirmación y devuelve los datos elegidos (o null si se cancela).
/// [subtotal] es lo que suman los productos; el delivery se suma aquí.
Future<CheckoutData?> showCheckoutSheet(BuildContext context, double subtotal) {
  return showModalBottomSheet<CheckoutData>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _CheckoutSheet(subtotal: subtotal),
    ),
  );
}

class _CheckoutSheet extends StatefulWidget {
  final double subtotal;
  const _CheckoutSheet({required this.subtotal});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _referencia = TextEditingController();
  final _pagaCon = TextEditingController();

  TipoEntrega _tipo = TipoEntrega.delivery;
  MetodoPago _metodo = MetodoPago.efectivo;
  LatLng? _ubicacion;
  bool _loading = true;
  String? _ubicacionError;

  double get _envio => _tipo == TipoEntrega.delivery ? costoDelivery : 0;
  double get _total => widget.subtotal + _envio;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Rellena con los datos del perfil del cliente.
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final d = doc.data() ?? {};
      _nombre.text = (d['name'] ?? d['nombre'] ?? '').toString();
      _telefono.text = (d['phone'] ?? '').toString();
      _direccion.text = (d['direccion'] ?? '').toString();
      _ubicacion = LocationService.fromMap(d['ubicacion']);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_nombre, _telefono, _direccion, _referencia, _pagaCon]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _pagaConValue =>
      double.tryParse(_pagaCon.text.replaceAll(',', '.'));

  /// Billetes sugeridos por encima del total.
  List<double> get _quickCash {
    final t = _total;
    final options = <double>{
      for (final step in [100, 500, 1000, 2000])
        if (step >= t / 4) (t / step).ceil() * step.toDouble(),
    }.where((v) => v > t).toList()..sort();
    return options.take(3).toList();
  }

  void _confirm() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _ubicacionError = _validarUbicacion());
    if (!formOk || _ubicacionError != null) return;
    Navigator.pop(
      context,
      CheckoutData(
        tipo: _tipo,
        cliente: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        direccion: _direccion.text.trim(),
        referencia: _referencia.text.trim(),
        metodoPago: _metodo,
        pagaCon: _metodo == MetodoPago.efectivo ? _pagaConValue : null,
        ubicacion: _ubicacion,
      ),
    );
  }

  /// El delivery solo llega dentro de la zona y necesita el punto en el mapa.
  String? _validarUbicacion() {
    if (_tipo != TipoEntrega.delivery) return null;
    final p = _ubicacion;
    if (p == null) {
      return 'Marca en el mapa dónde te entregamos';
    }
    if (!DeliveryZone.contiene(p)) {
      return 'Esa ubicación está fuera de nuestra zona de delivery '
          '(${DeliveryZone.nombre}). Elige otra o recoge en el local.';
    }
    return null;
  }

  String _money(double v) => 'RD\$ ${v.toStringAsFixed(2)}';

  Widget _row(String label, String value, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pagaCon = _pagaConValue;
    final devuelta = pagaCon == null ? 0.0 : pagaCon - _total;

    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Confirmar pedido', style: t.headlineSmall),
            const SizedBox(height: 4),
            _row('Productos', _money(widget.subtotal), t.bodyMedium),
            if (_tipo == TipoEntrega.delivery)
              _row('Delivery', _money(_envio), t.bodyMedium),
            _row(
              'Total a pagar',
              _money(_total),
              t.titleMedium?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 20),

            // ── Tipo de entrega ──
            SegmentedButton<TipoEntrega>(
              segments: const [
                ButtonSegment(
                  value: TipoEntrega.delivery,
                  icon: Icon(Icons.delivery_dining),
                  label: Text('Delivery'),
                ),
                ButtonSegment(
                  value: TipoEntrega.recoger,
                  icon: Icon(Icons.storefront),
                  label: Text('Recoger en local'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() {
                _tipo = s.first;
                _ubicacionError = null;
              }),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono / WhatsApp',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 7) {
                  return 'Escribe tu teléfono: te llamamos para confirmar el pedido';
                }
                if ((v ?? '').trim().length > 30) return 'Teléfono demasiado largo';
                return null;
              },
            ),

            if (_tipo == TipoEntrega.delivery) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Referencia de ubicación',
                  hintText: 'Sector, calle y cómo llegar a tu casa',
                  prefixIcon: Icon(Icons.signpost_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Escribe el sector y una referencia para llegar'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referencia,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Indicaciones extra (opcional)',
                  hintText: 'Ej: tocar el timbre, segundo piso',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              LocationCard(
                location: _ubicacion,
                onChanged: (p) => setState(() {
                  _ubicacion = p;
                  _ubicacionError = null;
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _ubicacionError ??
                      'Llevamos pedidos solo en ${DeliveryZone.nombre}. '
                          'Delivery: ${_money(costoDelivery)}.',
                  style: t.bodySmall?.copyWith(
                    color: _ubicacionError != null ? Colors.redAccent : null,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text('MÉTODO DE PAGO', style: t.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in MetodoPago.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: _metodo == m,
                    onSelected: (_) => setState(() => _metodo = m),
                  ),
              ],
            ),

            if (_metodo == MetodoPago.efectivo) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _pagaCon,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: '¿Con cuánto vas a pagar?',
                  hintText: 'Déjalo vacío si pagas exacto',
                  prefixText: 'RD\$ ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null) return 'Monto inválido';
                  if (n < _total) {
                    return 'Debe ser igual o mayor al total';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Exacto'),
                    onPressed: () => setState(() => _pagaCon.clear()),
                  ),
                  for (final v in _quickCash)
                    ActionChip(
                      label: Text('RD\$ ${v.toStringAsFixed(0)}'),
                      onPressed: () =>
                          setState(() => _pagaCon.text = v.toStringAsFixed(0)),
                    ),
                ],
              ),
              if (pagaCon != null && devuelta >= 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Tu devuelta')),
                      Text(
                        _money(devuelta),
                        style: t.titleMedium?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: Text(
                _tipo == TipoEntrega.delivery
                    ? 'Pedir delivery · ${_money(_total)}'
                    : 'Confirmar pedido · ${_money(_total)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
