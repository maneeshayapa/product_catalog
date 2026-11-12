import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/data/repositories/product_repository.dart';
import 'package:product_catalog/data/services/product_service.dart';
import 'package:product_catalog/providers/product_provider.dart';

void main() {
  late _FakeProductRepository repository;
  late ProductProvider provider;

  setUp(() {
    repository = _FakeProductRepository(
      [
        _product(1, 'Zebra', 20, 3.5, 'beauty'),
        _product(2, 'Apple', 10, 4.9, 'tools'),
        _product(3, 'Mango', 30, 4.2, 'beauty'),
        _product(4, 'Banana', 5, 4.7, 'tools'),
      ],
      categories: const ['beauty', 'tools'],
    );
    provider = ProductProvider(repository: repository);
  });

  test(
    'selecting a category filters products and All restores every result',
    () async {
      await provider.fetchCategories();
      await provider.fetchProducts();

      expect(provider.categories, ['beauty', 'tools']);

      provider.selectCategory('beauty');
      expect(provider.selectedCategory, 'beauty');
      expect(provider.products.map((product) => product.id), [1, 3]);

      provider.selectCategory('All');
      expect(provider.selectedCategory, 'All');
      expect(provider.products, hasLength(4));
    },
  );

  test('sorts products by price from low to high', () async {
    await provider.fetchProducts();
    provider.setSortOption(ProductSortOption.priceLowToHigh);

    expect(provider.products.map((product) => product.price), [5, 10, 20, 30]);
  });

  test('sorts products by price from high to low', () async {
    await provider.fetchProducts();
    provider.setSortOption(ProductSortOption.priceHighToLow);

    expect(provider.products.map((product) => product.price), [30, 20, 10, 5]);
  });

  test('sorts products by highest rating first', () async {
    await provider.fetchProducts();
    provider.setSortOption(ProductSortOption.ratingHighestFirst);

    expect(provider.products.map((product) => product.rating), [
      4.9,
      4.7,
      4.2,
      3.5,
    ]);
  });

  test('sorts products alphabetically by name', () async {
    await provider.fetchProducts();
    provider.setSortOption(ProductSortOption.nameAToZ);

    expect(provider.products.map((product) => product.title), [
      'Apple',
      'Banana',
      'Mango',
      'Zebra',
    ]);
  });

  test(
    'search, category filtering, and pagination retain the chosen sort',
    () async {
      final products = List<Product>.generate(
        23,
        (index) => _product(
          index,
          'Needle product ${index.toString().padLeft(2, '0')}',
          (index + 1).toDouble(),
          (index % 5 + 1).toDouble(),
          index.isEven ? 'beauty' : 'tools',
        ),
      );
      repository = _FakeProductRepository(
        products,
        categories: const ['beauty', 'tools'],
      );
      provider = ProductProvider(repository: repository);

      await provider.fetchCategories();
      await provider.fetchProducts(search: 'needle');
      final requestCount = repository.requests.length;
      provider.selectCategory('beauty');
      provider.setSortOption(ProductSortOption.priceHighToLow);

      expect(provider.products, hasLength(5));
      expect(repository.requests, hasLength(requestCount));
      expect(
        provider.products.every(
          (product) =>
              product.category == 'beauty' &&
              product.title.toLowerCase().contains('needle'),
        ),
        isTrue,
      );

      await provider.loadMore();

      expect(provider.products, hasLength(10));
      expect(provider.hasMore, isTrue);

      await provider.loadMore();

      expect(provider.products, hasLength(12));
      expect(provider.sortOption, ProductSortOption.priceHighToLow);
      expect(
        provider.products.map((product) => product.price),
        orderedEquals(
          provider.products.map((product) => product.price).toList()
            ..sort((a, b) => b.compareTo(a)),
        ),
      );
      expect(
        repository.requests.every((request) => request.$2 == 'needle'),
        isTrue,
      );
      expect(provider.hasMore, isFalse);
    },
  );
}

Product _product(
  int id,
  String title,
  double price,
  double rating,
  String category,
) {
  return Product(
    id: id,
    title: title,
    description: '',
    price: price,
    rating: rating,
    stock: 5,
    thumbnail: '',
    images: const [],
    category: category,
  );
}

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository(this.products, {this.categories = const []})
    : super(productService: ProductService());

  final List<Product> products;
  final List<String> categories;
  final List<(int, String?)> requests = [];

  @override
  Future<List<Product>> getProducts({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    requests.add((skip, search));
    final filteredProducts = products
        .where(
          (product) =>
              search == null ||
              product.title.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    return filteredProducts.skip(skip).take(limit).toList();
  }

  @override
  Future<List<String>> getCategories() async => categories;
}
