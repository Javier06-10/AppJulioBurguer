class CartItem {
  final String productId;
  final String nombre;
  final double precio;
  final int tiempoPreparacion;

  int cantidad;


  CartItem({
    required this.productId,
    required this.nombre,
    required this.precio,
    required this.tiempoPreparacion,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}
