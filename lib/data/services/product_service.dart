
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
      final bool isSearching =
          search != null && search.trim().isNotEmpty;

      final String endpoint = isSearching
          ? '/products/search'
          : '/products';

      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {
          'limit': limit.toString(),
          'skip': skip.toString(),
          if (isSearching) 'q': search.trim(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        final List productsJson = data['products'];

        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load products: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Unable to fetch products: $e');
    }
  }
}
