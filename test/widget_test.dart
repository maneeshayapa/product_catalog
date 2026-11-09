import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/data/repositories/product_repository.dart';
import 'package:product_catalog/data/services/product_service.dart';
import 'package:product_catalog/providers/cart_provider.dart';
import 'package:product_catalog/providers/product_provider.dart';
import 'package:product_catalog/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens product details and confirms Add to Cart', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final product = Product(
      id: 1,
      title: 'A useful product',
      description: 'A product description.',
      price: 19.99,
      rating: 4.5,
      stock: 8,
      thumbnail: '',
      images: const [],
    );
    final cartProvider = await CartProvider.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                ProductProvider(repository: _FakeProductRepository(product)),
          ),
          ChangeNotifierProvider.value(value: cartProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A useful product'));
    await tester.pumpAndSettle();

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('A product description.'), findsOneWidget);
    expect(find.text('\$19.99'), findsOneWidget);
    expect(find.text('8 in stock'), findsOneWidget);

    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Added to Cart!'), findsOneWidget);
    expect(find.text('Product added successfully'), findsOneWidget);
    expect(find.text('A useful product'), findsNWidgets(2));
    expect(find.text('VIEW CART'), findsOneWidget);
    expect(cartProvider.itemCount, 1);

    await tester.tap(find.text('VIEW CART'));
    await tester.pumpAndSettle();

    expect(find.text('Shopping Cart'), findsOneWidget);
    expect(cartProvider.itemCount, 1);
  });
}

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository(this.product)
    : super(productService: ProductService());

  final Product product;

  @override
  Future<List<Product>> getProducts({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    if (skip > 0) return [];
    if (search != null && !product.title.toLowerCase().contains(search)) {
      return [];
    }
    return [product];
  }
}
