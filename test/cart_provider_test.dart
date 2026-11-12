import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late CartProvider cart;
  late Product product;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    cart = await CartProvider.create(preferences: preferences);
    product = Product(
      id: 1,
      title: 'Test product',
      description: 'A test product.',
      price: 12.50,
      rating: 4.5,
      stock: 5,
      thumbnail: 'https://example.com/product.png',
      images: const ['https://example.com/product-detail.png'],
    );
  });

  test('saves a product and its serialized data', () async {
    await cart.addToCart(product);

    final storedJson = preferences.getString(CartProvider.storageKey);
    expect(storedJson, isNotNull);
    final storedCart = jsonDecode(storedJson!) as List<dynamic>;
    expect(storedCart.single['product'], product.toJson());
    expect(storedCart.single['quantity'], 1);
  });

  test('persists quantity increases and decreases', () async {
    await cart.addToCart(product);
    await cart.increaseQuantity(product.id);

    var restoredCart = await CartProvider.create(preferences: preferences);
    expect(restoredCart.items.single.quantity, 2);

    await cart.decreaseQuantity(product.id);
    restoredCart = await CartProvider.create(preferences: preferences);

    expect(restoredCart.items.single.quantity, 1);
    expect(restoredCart.totalPrice, 12.50);
  });

  test('removed products stay removed after restoration', () async {
    await cart.addToCart(product);
    await cart.removeFromCart(product.id);

    final restoredCart = await CartProvider.create(preferences: preferences);
    expect(restoredCart.items, isEmpty);
    expect(preferences.getString(CartProvider.storageKey), '[]');
  });

  test('restores cart data after creating a new provider', () async {
    await cart.addToCart(product);
    await cart.addToCart(product);

    final restartedCart = await CartProvider.create(preferences: preferences);

    expect(restartedCart.items, hasLength(1));
    expect(restartedCart.items.single.product.title, product.title);
    expect(restartedCart.items.single.quantity, 2);
    expect(restartedCart.itemCount, 2);
    expect(restartedCart.totalPrice, 25.0);
  });

  test('restores an empty cart', () async {
    await cart.addToCart(product);
    await cart.removeFromCart(product.id);

    final restartedCart = await CartProvider.create(preferences: preferences);

    expect(restartedCart.items, isEmpty);
    expect(restartedCart.itemCount, 0);
    expect(restartedCart.totalPrice, 0);
  });

  test('invalid stored JSON produces a safe empty cart', () async {
    SharedPreferences.setMockInitialValues({
      CartProvider.storageKey: '{invalid json',
    });
    preferences = await SharedPreferences.getInstance();

    final restoredCart = await CartProvider.create(preferences: preferences);

    expect(restoredCart.items, isEmpty);
    expect(restoredCart.itemCount, 0);
    expect(restoredCart.totalPrice, 0);
    expect(restoredCart.persistenceError, isNotNull);
  });
}
