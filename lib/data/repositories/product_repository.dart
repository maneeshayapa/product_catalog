import '../models/product.dart';
import '../services/product_service.dart';

class ProductRepository {
  final ProductService productService;

  ProductRepository({required this.productService});

  Future<List<Product>> getProducts({
    int limit = 10,
    int skip = 0,
    String? search,
  }) {
    return productService.fetchProducts(
      limit: limit,
      skip: skip,
      search: search,
    );
  }

  Future<List<Product>> getProductsByCategory(
    String category, {
    int limit = 10,
  }) {
    return productService.fetchProductsByCategory(category, limit: limit);
  }
}
