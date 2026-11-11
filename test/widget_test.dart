import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/data/models/product_review.dart';
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
      brand: 'Catalog brand',
      category: 'test-category',
      discountPercentage: 10,
      availabilityStatus: 'In Stock',
      warrantyInformation: 'One year warranty',
      shippingInformation: 'Ships in three days',
      returnPolicy: '30-day returns',
      reviews: [
        ProductReview(
          rating: 5,
          comment: 'Excellent quality',
          date: DateTime.utc(2025, 1, 15),
          reviewerName: 'Alex Reviewer',
          reviewerEmail: 'alex@example.com',
        ),
      ],
    );
    final relatedProduct = Product(
      id: 2,
      title: 'Related product',
      description: 'Another product.',
      price: 9.99,
      rating: 4.2,
      stock: 3,
      thumbnail: '',
      images: const [],
      category: 'test-category',
    );
    final cartProvider = await CartProvider.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ProductProvider(
              repository: _FakeProductRepository(
                product,
                relatedProducts: [product, relatedProduct],
              ),
            ),
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
    expect(find.textContaining('8 in stock'), findsOneWidget);
    expect(find.text('Catalog brand'), findsOneWidget);
    expect(find.text('One year warranty'), findsOneWidget);
    expect(find.text('Customer Reviews'), findsOneWidget);
    expect(find.text('Excellent quality'), findsOneWidget);
    expect(find.text('01/15/2025'), findsOneWidget);
    expect(find.text('Related product'), findsOneWidget);

    await tester.ensureVisible(find.text('Related product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Related product'));
    await tester.pumpAndSettle();
    expect(find.text('Another product.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

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
  _FakeProductRepository(this.product, {this.relatedProducts = const []})
    : super(productService: ProductService());

  final Product product;
  final List<Product> relatedProducts;

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

  @override
  Future<List<Product>> getProductsByCategory(
    String category, {
    int limit = 10,
  }) async {
    return relatedProducts;
  }
}
