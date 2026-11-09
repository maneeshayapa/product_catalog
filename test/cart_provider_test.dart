import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/providers/cart_provider.dart';

void main() {
  late CartProvider cart;
  late Product product;

  setUp(() {
    cart = CartProvider();
    product = Product(
      id: 1,
      title: 'Test product',
      description: 'A test product.',
      price: 12.50,
      rating: 4.5,
      stock: 5,
      thumbnail: '',
      images: const [],
    );
  });

  test('adding the same product increases its quantity', () {
    cart.addToCart(product);
    cart.addToCart(product);

    expect(cart.items, hasLength(1));
    expect(cart.items.single.quantity, 2);
    expect(cart.itemCount, 2);
    expect(cart.totalPrice, 25.0);
  });

  test('quantity changes update the item count and total', () {
    cart.addToCart(product);
    cart.increaseQuantity(product.id);

    expect(cart.itemCount, 2);
    expect(cart.totalPrice, 25.0);

    cart.decreaseQuantity(product.id);

    expect(cart.items.single.quantity, 1);
    expect(cart.itemCount, 1);
    expect(cart.totalPrice, 12.50);
  });

  test('removing a product clears its quantity and total', () {
    cart.addToCart(product);
    cart.increaseQuantity(product.id);
    cart.removeFromCart(product.id);

    expect(cart.items, isEmpty);
    expect(cart.itemCount, 0);
    expect(cart.totalPrice, 0);
  });
}
