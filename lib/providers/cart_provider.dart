import 'package:flutter/foundation.dart';

import '../data/models/product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  double get totalPrice =>
      _items.values.fold(0, (total, item) => total + item.totalPrice);

  void addToCart(Product product) {
    final existingItem = _items[product.id];
    if (existingItem == null) {
      _items[product.id] = CartItem(product: product);
    } else {
      existingItem.quantity++;
    }
    notifyListeners();
  }

  void increaseQuantity(int productId) {
    final item = _items[productId];
    if (item == null) return;

    item.quantity++;
    notifyListeners();
  }

  void decreaseQuantity(int productId) {
    final item = _items[productId];
    if (item == null || item.quantity <= 1) return;

    item.quantity--;
    notifyListeners();
  }

  void removeFromCart(int productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }
}
