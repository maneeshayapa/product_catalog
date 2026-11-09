import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/product.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {'product': product.toJson(), 'quantity': quantity};
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = Map<String, dynamic>.from(
      json['product'] as Map<dynamic, dynamic>,
    );
    final quantity = json['quantity'];
    if (quantity is! int || quantity < 1) {
      throw const FormatException('Cart item quantity must be positive.');
    }

    return CartItem(product: Product.fromJson(productJson), quantity: quantity);
  }
}

class CartProvider extends ChangeNotifier {
  CartProvider._(this._preferences);

  static const String storageKey = 'product_catalog_cart';

  static Future<CartProvider> create({SharedPreferences? preferences}) async {
    final cart = CartProvider._(
      preferences ?? await SharedPreferences.getInstance(),
    );
    await cart._restoreCart();
    return cart;
  }

  final SharedPreferences _preferences;
  final Map<int, CartItem> _items = {};
  Future<void> _saveQueue = Future<void>.value();
  String? _persistenceError;

  List<CartItem> get items => List.unmodifiable(_items.values);

  String? get persistenceError => _persistenceError;

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  double get totalPrice =>
      _items.values.fold(0, (total, item) => total + item.totalPrice);

  Future<void> addToCart(Product product) async {
    final existingItem = _items[product.id];
    _items[product.id] = CartItem(
      product: product,
      quantity: (existingItem?.quantity ?? 0) + 1,
    );
    notifyListeners();
    await _saveCart();
  }

  Future<void> increaseQuantity(int productId) async {
    final item = _items[productId];
    if (item == null) return;

    _items[productId] = CartItem(
      product: item.product,
      quantity: item.quantity + 1,
    );
    notifyListeners();
    await _saveCart();
  }

  Future<void> decreaseQuantity(int productId) async {
    final item = _items[productId];
    if (item == null || item.quantity <= 1) return;

    _items[productId] = CartItem(
      product: item.product,
      quantity: item.quantity - 1,
    );
    notifyListeners();
    await _saveCart();
  }

  Future<void> removeFromCart(int productId) async {
    if (_items.remove(productId) != null) {
      notifyListeners();
      await _saveCart();
    }
  }

  Future<void> _restoreCart() async {
    try {
      final savedCart = _preferences.getString(storageKey);
      if (savedCart == null || savedCart.isEmpty) return;

      final decoded = jsonDecode(savedCart);
      if (decoded is! List) {
        throw const FormatException('Saved cart must be a list.');
      }

      final restoredItems = <int, CartItem>{};
      for (final entry in decoded) {
        if (entry is! Map) {
          throw const FormatException('Saved cart item must be an object.');
        }
        final item = CartItem.fromJson(Map<String, dynamic>.from(entry));
        restoredItems[item.product.id] = item;
      }
      _items.addAll(restoredItems);
    } catch (error) {
      _items.clear();
      _persistenceError = 'Unable to restore saved cart: $error';
    }
  }

  Future<void> _saveCart() {
    final encodedCart = jsonEncode(
      _items.values.map((item) => item.toJson()).toList(),
    );

    _saveQueue = _saveQueue.then((_) async {
      try {
        final saved = await _preferences.setString(storageKey, encodedCart);
        if (!saved) {
          throw StateError('SharedPreferences did not save the cart.');
        }
        _persistenceError = null;
      } catch (error) {
        _persistenceError = 'Unable to save cart: $error';
      }
    });

    return _saveQueue;
  }
}
