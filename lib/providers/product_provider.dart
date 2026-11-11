import 'package:flutter/material.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository repository;

  ProductProvider({required this.repository});

  List<Product> _products = [];

  List<Product> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _skip = 0;
  final int _limit = 10;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _currentSearch;
  int _requestId = 0;

  Future<List<Product>> fetchRelatedProducts({
    required String category,
    required int excludeProductId,
  }) async {
    final products = await repository.getProductsByCategory(
      category,
      limit: 12,
    );
    return products.where((product) => product.id != excludeProductId).toList();
  }

  Future<void> fetchProducts({String? search}) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _products = [];
    _skip = 0;
    _hasMore = true;
    final query = search?.trim();
    _currentSearch = query == null || query.isEmpty ? null : query;

    notifyListeners();

    try {
      final result = await repository.getProducts(
        limit: _limit,
        skip: _skip,
        search: _currentSearch,
      );

      if (requestId != _requestId) return;
      _products = result;
      _skip = result.length;
      _hasMore = result.length == _limit;
    } catch (e) {
      if (requestId == _requestId) {
        _errorMessage = e.toString();
      }
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getProducts(
        limit: _limit,
        skip: _skip,
        search: _currentSearch,
      );

      if (requestId != _requestId) return;
      _products.addAll(result);
      _skip += result.length;
      _hasMore = result.length == _limit;
    } catch (e) {
      if (requestId == _requestId) {
        _errorMessage = e.toString();
      }
    } finally {
      if (requestId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
