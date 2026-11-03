import 'package:latlong2/latlong.dart';

/// Datos de entrega y pago que el cliente indica al confirmar el pedido.
/// Se guardan dentro del pedido (`orders.entrega` y `orders.pago`) para que
/// el repartidor los vea sin depender del perfil del usuario.
enum TipoEntrega { delivery, recoger }

enum MetodoPago { efectivo, transferencia, tarjeta }

extension MetodoPagoLabel on MetodoPago {
  String get label => switch (this) {
    MetodoPago.efectivo => 'Efectivo',
    MetodoPago.transferencia => 'Transferencia',
    MetodoPago.tarjeta => 'Tarjeta',
  };
}

class CheckoutData {
  final TipoEntrega tipo;
  final String cliente;
  final String telefono;
  final String direccion;
  final String referencia;

  /// Punto exacto elegido en el mapa (solo delivery).
  final LatLng? ubicacion;
  final MetodoPago metodoPago;

  /// Billete con el que paga (solo efectivo). null = paga exacto.
  final double? pagaCon;

  const CheckoutData({
    required this.tipo,
    required this.cliente,
    required this.telefono,
    required this.direccion,
    required this.referencia,
    required this.metodoPago,
    this.pagaCon,
    this.ubicacion,
  });

  double devuelta(double total) =>
      pagaCon == null ? 0 : (pagaCon! - total).clamp(0, double.infinity);

  Map<String, dynamic> entregaMap() => {
    'tipo': tipo.name,
    'cliente': cliente,
    'telefono': telefono,
    'direccion': tipo == TipoEntrega.delivery ? direccion : '',
    'referencia': tipo == TipoEntrega.delivery ? referencia : '',
    if (tipo == TipoEntrega.delivery && ubicacion != null)
      'ubicacion': {'lat': ubicacion!.latitude, 'lng': ubicacion!.longitude},
  };

  Map<String, dynamic> pagoMap(double total) => {
    'metodo': metodoPago.name,
    'pagaCon': metodoPago == MetodoPago.efectivo ? (pagaCon ?? total) : total,
    'devuelta': metodoPago == MetodoPago.efectivo ? devuelta(total) : 0,
  };
}
