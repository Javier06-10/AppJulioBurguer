import 'package:flutter_julioburguer/models/checkout_data.dart';
import 'package:flutter_julioburguer/services/delivery_zone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

CheckoutData _checkout(TipoEntrega tipo) => CheckoutData(
  tipo: tipo,
  cliente: 'Ana',
  telefono: '8095551234',
  direccion: 'Calle Duarte 10',
  referencia: '',
  metodoPago: MetodoPago.efectivo,
);

void main() {
  group('Zona de delivery (San José de los Llanos)', () {
    test('el centro del pueblo está dentro', () {
      expect(DeliveryZone.contiene(DeliveryZone.centro), isTrue);
    });

    test('un punto a ~3 km sigue dentro', () {
      expect(DeliveryZone.contiene(const LatLng(18.6476, -69.4956)), isTrue);
    });

    test('un punto a ~5 km queda fuera', () {
      expect(DeliveryZone.contiene(const LatLng(18.6656, -69.4956)), isFalse);
    });

    test('San Pedro de Macorís y Santo Domingo quedan fuera', () {
      expect(DeliveryZone.contiene(const LatLng(18.4539, -69.3086)), isFalse);
      expect(DeliveryZone.contiene(const LatLng(18.4861, -69.9312)), isFalse);
    });
  });

  group('Cargo de delivery', () {
    test('delivery suma RD\$50', () {
      final c = _checkout(TipoEntrega.delivery);
      expect(c.costoEnvio, 50);
      expect(c.totalCon(350), 400);
    });

    test('recoger en el local no paga delivery', () {
      final c = _checkout(TipoEntrega.recoger);
      expect(c.costoEnvio, 0);
      expect(c.totalCon(350), 350);
    });
  });
}
