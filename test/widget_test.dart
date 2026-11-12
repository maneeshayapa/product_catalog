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

  testWidgets('category and sorting controls filter and order products', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _CatalogProductRepository([
      _catalogProduct(
        id: 1,
        title: 'Glow serum',
        price: 10,
        rating: 4.2,
        category: 'beauty',
      ),
      _catalogProduct(
        id: 2,
        title: 'Daily moisturizer',
        price: 20,
        rating: 4.8,
        category: 'beauty',
      ),
      _catalogProduct(
        id: 3,
        title: 'Compact camera',
        price: 30,
        rating: 4.5,
        category: 'electronics',
      ),
    ]);
    final productProvider = ProductProvider(repository: repository);
    final cartProvider = await CartProvider.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider.value(value: cartProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-chip-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('category-chip-beauty')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-chip-electronics')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('product-sort-dropdown')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-chip-beauty')));
    await tester.pumpAndSettle();
    expect(productProvider.products.map((product) => product.id), [1, 2]);
    expect(repository.productFetchCount, 1);

    await tester.tap(find.byKey(const ValueKey('product-sort-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: High to Low').last);
    await tester.pumpAndSettle();
    expect(productProvider.products.map((product) => product.id), [2, 1]);
    expect(repository.productFetchCount, 1);

    await tester.enterText(find.byType(TextField), 'Glow serum');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(productProvider.products.map((product) => product.id), [1]);
    expect(repository.lastSearch, 'Glow serum');
  });
}

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository(this.product, {this.relatedProducts = const []})
    : super(productService: ProductService());

  final Product product;
  final List<Product> relatedProducts;

  @override
  Future<List<String>> getCategories() async {
    final category = product.category;
    return category == null ? [] : [category];
  }

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

class _CatalogProductRepository extends ProductRepository {
  _CatalogProductRepository(this.catalog)
    : super(productService: ProductService());

  final List<Product> catalog;
  int productFetchCount = 0;
  String? lastSearch;

  @override
  Future<List<String>> getCategories() async => ['beauty', 'electronics'];

  @override
  Future<List<Product>> getProducts({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    productFetchCount++;
    lastSearch = search;
    final matches = search == null
        ? catalog
        : catalog
              .where(
                (product) =>
                    product.title.toLowerCase().contains(search.toLowerCase()),
              )
              .toList();
    return matches.skip(skip).take(limit).toList();
  }
}

Product _catalogProduct({
  required int id,
  required String title,
  required double price,
  required double rating,
  required String category,
}) {
  return Product(
    id: id,
    title: title,
    description: '$title description',
    price: price,
    rating: rating,
    stock: 5,
    thumbnail: '',
    images: const [],
    category: category,
  );
}
