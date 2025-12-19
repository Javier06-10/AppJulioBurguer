import 'package:flutter/material.dart';
import 'package:flutter_julioburguer/models/models/cart_item.dart';


class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;
  

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.cantidad);

  double get total =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  void addItem(
  String productId,
  String nombre,
  double precio,
  int tiempoPreparacion,
  
) {
  if (_items.containsKey(productId)) {
  _items[productId]!.cantidad++;
} else {
  _items[productId] = CartItem(
    productId: productId,
    nombre: nombre,
    precio: precio,
    cantidad: 1,
    
    tiempoPreparacion: tiempoPreparacion,
  );
}

notifyListeners();
}

  

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void decreaseItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.cantidad > 1) {
      _items[productId]!.cantidad--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
