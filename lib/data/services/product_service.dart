import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://dummyjson.com';

  Future<List<Product>> fetchProducts({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    try {
      final bool isSearching = search != null && search.trim().isNotEmpty;

      final String endpoint = isSearching ? '/products/search' : '/products';

      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {
          'limit': limit.toString(),
          'skip': skip.toString(),
          if (isSearching) 'q': search.trim(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _decodeProducts(response.body);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Unable to fetch products: $e');
    }
  }

  Future<List<Product>> fetchProductsByCategory(
    String category, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/products/category/${Uri.encodeComponent(category)}',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _decodeProducts(response.body);
      }
      throw Exception(
        'Failed to load related products: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Unable to fetch related products: $e');
    }
  }

  Future<List<String>> fetchCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/products/category-list'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load product categories: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.any((category) => category is! String)) {
        throw const FormatException(
          'Category response must be a list of strings.',
        );
      }
      return decoded.cast<String>();
    } catch (e) {
      throw Exception('Unable to fetch product categories: $e');
    }
  }

  List<Product> _decodeProducts(String responseBody) {
    final Map<String, dynamic> data = jsonDecode(responseBody);
    final productsJson = data['products'];
    if (productsJson is! List) {
      throw const FormatException('Product response must contain a list.');
    }
    return productsJson
        .whereType<Map>()
        .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
