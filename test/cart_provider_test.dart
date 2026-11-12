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
    final result = await cart.addToCart(product);

    expect(result, CartOperationResult.success);
    final storedJson = preferences.getString(CartProvider.storageKey);
    expect(storedJson, isNotNull);
    final storedCart = jsonDecode(storedJson!) as List<dynamic>;
    expect(storedCart.single['product'], product.toJson());
    expect(storedCart.single['quantity'], 1);
  });

  test('persists quantity increases and decreases', () async {
    await cart.addToCart(product);
    expect(
      await cart.increaseQuantity(product.id),
      CartOperationResult.success,
    );

    var restoredCart = await CartProvider.create(preferences: preferences);
    expect(restoredCart.items.single.quantity, 2);

    expect(
      await cart.decreaseQuantity(product.id),
      CartOperationResult.success,
    );
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

  test('rejects adding a product with no stock', () async {
    final outOfStockProduct = Product(
      id: 2,
      title: 'Out of stock product',
      description: '',
      price: 5,
      rating: 4,
      stock: 0,
      thumbnail: '',
      images: const [],
    );

    expect(
      await cart.addToCart(outOfStockProduct),
      CartOperationResult.outOfStock,
    );
    expect(cart.items, isEmpty);
    expect(cart.itemCount, 0);
    expect(cart.totalPrice, 0);
  });

  test('rejects adding an existing item beyond available stock', () async {
    final limitedProduct = Product(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      rating: product.rating,
      stock: 2,
      thumbnail: product.thumbnail,
      images: product.images,
    );

    expect(await cart.addToCart(limitedProduct), CartOperationResult.success);
    expect(await cart.addToCart(limitedProduct), CartOperationResult.success);
    expect(
      await cart.addToCart(limitedProduct),
      CartOperationResult.stockLimitReached,
    );
    expect(cart.items.single.quantity, 2);
    expect(cart.totalPrice, 25);
  });

  test(
    'rejects cart quantity increases beyond stock and permits decreases',
    () async {
      final limitedProduct = Product(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        rating: product.rating,
        stock: 2,
        thumbnail: product.thumbnail,
        images: product.images,
      );
      await cart.addToCart(limitedProduct);
      await cart.increaseQuantity(product.id);

      expect(
        await cart.increaseQuantity(product.id),
        CartOperationResult.stockLimitReached,
      );
      expect(cart.items.single.quantity, 2);
      expect(
        await cart.decreaseQuantity(product.id),
        CartOperationResult.success,
      );
      expect(cart.items.single.quantity, 1);
      expect(cart.itemCount, 1);
      expect(cart.totalPrice, 12.50);
    },
  );

  test(
    'repairs persisted quantities to current stock and drops zero-stock items',
    () async {
      final zeroStockProduct = Product(
        id: 2,
        title: 'Unavailable product',
        description: '',
        price: 8,
        rating: 3,
        stock: 0,
        thumbnail: '',
        images: const [],
      );
      SharedPreferences.setMockInitialValues({
        CartProvider.storageKey: jsonEncode([
          {'product': product.toJson(), 'quantity': product.stock + 5},
          {'product': zeroStockProduct.toJson(), 'quantity': 1},
          {'product': product.toJson(), 'quantity': 0},
        ]),
      });
      preferences = await SharedPreferences.getInstance();

      final restoredCart = await CartProvider.create(preferences: preferences);

      expect(restoredCart.items, hasLength(1));
      expect(restoredCart.items.single.quantity, product.stock);
      expect(restoredCart.itemCount, product.stock);
      expect(restoredCart.totalPrice, product.price * product.stock);
      final savedCart =
          jsonDecode(preferences.getString(CartProvider.storageKey)!) as List;
      expect(savedCart, hasLength(1));
      expect(savedCart.single['quantity'], product.stock);
    },
  );

  test('removing a cart item keeps the cart empty and persisted', () async {
    await cart.addToCart(product);

    await cart.removeFromCart(product.id);

    expect(cart.items, isEmpty);
    expect(cart.itemCount, 0);
    expect(cart.totalPrice, 0);
    expect(preferences.getString(CartProvider.storageKey), '[]');
  });
}
