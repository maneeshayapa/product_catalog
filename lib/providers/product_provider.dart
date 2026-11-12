import 'package:flutter/material.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

enum ProductSortOption {
  defaultOrder('Default'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  ratingHighestFirst('Rating: Highest First'),
  nameAToZ('Name: A–Z');

  const ProductSortOption(this.label);

  final String label;
}

class ProductProvider extends ChangeNotifier {
  final ProductRepository repository;

  ProductProvider({required this.repository});

  List<Product> _products = [];

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
  String? _selectedCategory;
  ProductSortOption _sortOption = ProductSortOption.defaultOrder;
  int _requestId = 0;

  List<String> _categories = [];
  List<String> get categories => _categories;

  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  String? _categoriesErrorMessage;
  String? get categoriesErrorMessage => _categoriesErrorMessage;

  String? get selectedCategory => _selectedCategory;

  ProductSortOption get sortOption => _sortOption;

  List<Product> get products {
    final sortedProducts = List<Product>.of(_products);
    switch (_sortOption) {
      case ProductSortOption.defaultOrder:
        break;
      case ProductSortOption.priceLowToHigh:
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
      case ProductSortOption.priceHighToLow:
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
      case ProductSortOption.ratingHighestFirst:
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSortOption.nameAToZ:
        sortedProducts.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return sortedProducts;
  }

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _categoriesErrorMessage = null;
    notifyListeners();

    try {
      _categories = await repository.getCategories();
    } catch (error) {
      _categoriesErrorMessage = error.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(String? category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await fetchProducts(search: _currentSearch);
  }

  void setSortOption(ProductSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    notifyListeners();
  }

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
      while (_products.length < _limit && _hasMore) {
        final result = await repository.getProducts(
          limit: _limit,
          skip: _skip,
          search: _currentSearch,
        );
        if (requestId != _requestId) return;
        _appendMatchingProducts(result);
      }
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
      final targetCount = _products.length + _limit;
      while (_products.length < targetCount && _hasMore) {
        final result = await repository.getProducts(
          limit: _limit,
          skip: _skip,
          search: _currentSearch,
        );
        if (requestId != _requestId) return;
        _appendMatchingProducts(result);
      }
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

  void _appendMatchingProducts(List<Product> products) {
    _skip += products.length;
    _hasMore = products.length == _limit;
    _products.addAll(
      products.where(
        (product) =>
            _selectedCategory == null || product.category == _selectedCategory,
      ),
    );
  }
}
