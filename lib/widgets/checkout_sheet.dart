import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:latlong2/latlong.dart';

import '../models/checkout_data.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'location_card.dart';

/// Abre la hoja de confirmación y devuelve los datos elegidos (o null si se cancela).
Future<CheckoutData?> showCheckoutSheet(BuildContext context, double total) {
  return showModalBottomSheet<CheckoutData>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _CheckoutSheet(total: total),
    ),
  );
}

class _CheckoutSheet extends StatefulWidget {
  final double total;
  const _CheckoutSheet({required this.total});

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
    final t = widget.total;
    final options = <double>{
      for (final step in [100, 500, 1000, 2000])
        if (step >= t / 4) (t / step).ceil() * step.toDouble(),
    }.where((v) => v > t).toList()..sort();
    return options.take(3).toList();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
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

  String _money(double v) => 'RD\$ ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pagaCon = _pagaConValue;
    final devuelta = pagaCon == null ? 0.0 : pagaCon - widget.total;

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
            Text(
              'Total a pagar: ${_money(widget.total)}',
              style: t.bodyMedium?.copyWith(color: AppColors.primary),
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
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
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
              validator: (v) =>
                  _tipo == TipoEntrega.delivery &&
                      (v == null || v.trim().length < 7)
                  ? 'El repartidor necesita tu teléfono'
                  : null,
            ),

            if (_tipo == TipoEntrega.delivery) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega',
                  hintText: 'Calle, número, sector',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Escribe la dirección de entrega'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referencia,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  hintText: 'Ej: casa verde frente al colmado',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              LocationCard(
                location: _ubicacion,
                onChanged: (p) => setState(() => _ubicacion = p),
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
                  if (n < widget.total) {
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
                    ? 'Pedir delivery · ${_money(widget.total)}'
                    : 'Confirmar pedido · ${_money(widget.total)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
