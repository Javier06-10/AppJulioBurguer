import 'package:flutter/material.dart';
import 'package:flutter_julioburguer/models/product_model.dart';
import 'package:flutter_julioburguer/pages/product_detail_screen.dart';
import 'package:flutter_julioburguer/providers/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Product _product({int stock = 3}) => Product(
      id: 'p1',
      nombre: 'Yaroa grande',
      descripcion: 'papa, carne de pollo, queso',
      precio: 350,
      stock: stock,
      activo: true,
      categoriaId: null,
      tiempoPreparacion: 20,
    );

Future<CartProvider> _pump(WidgetTester tester, Product p) async {
  final cart = CartProvider();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: p),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return cart;
}

void main() {
  testWidgets('la cantidad sube hasta el stock y se agrega al carrito',
      (tester) async {
    final cart = await _pump(tester, _product(stock: 3));

    expect(find.text('Agregar · RD\$ 350'), findsOneWidget);

    final plus = find.byTooltip('Agregar uno');
    await tester.tap(plus);
    await tester.pump();
    await tester.tap(plus);
    await tester.pump();
    expect(find.text('Agregar · RD\$ 1050'), findsOneWidget);

    // No pasa del stock disponible
    await tester.tap(plus);
    await tester.pump();
    expect(find.text('Agregar · RD\$ 1050'), findsOneWidget);

    await tester.tap(find.text('Agregar · RD\$ 1050'));
    await tester.pumpAndSettle();
    expect(cart.totalItems, 3);
    expect(find.text('3 × Yaroa grande agregados al carrito'), findsOneWidget);
  });

  testWidgets('un producto agotado no se puede agregar', (tester) async {
    await _pump(tester, _product(stock: 0));
    expect(find.text('Agotado por ahora'), findsOneWidget);
    expect(find.byTooltip('Agregar uno'), findsNothing);
  });
}
