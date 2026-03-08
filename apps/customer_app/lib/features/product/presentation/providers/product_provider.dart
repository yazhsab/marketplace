import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/paginated_list.dart';
import '../../data/models/product_model.dart';

// Product list state
class ProductListState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final PaginatedList<ProductModel> products;
  final String? categoryFilter;
  final String? sortBy;
  final double? minPrice;
  final double? maxPrice;

  const ProductListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.products = const PaginatedList(items: [], total: 0, page: 1, perPage: 20),
    this.categoryFilter,
    this.sortBy,
    this.minPrice,
    this.maxPrice,
  });

  ProductListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    PaginatedList<ProductModel>? products,
    String? categoryFilter,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) {
    return ProductListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      products: products ?? this.products,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final Ref _ref;

  ProductListNotifier(this._ref) : super(const ProductListState()) {
    loadProducts();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{
        'page': 1,
        'perPage': AppConstants.defaultPageSize,
      };

      if (state.categoryFilter != null) {
        queryParams['category'] = state.categoryFilter;
      }
      if (state.sortBy != null) {
        queryParams['sortBy'] = state.sortBy;
      }
      if (state.minPrice != null) {
        queryParams['minPrice'] = state.minPrice;
      }
      if (state.maxPrice != null) {
        queryParams['maxPrice'] = state.maxPrice;
      }

      final response = await apiClient.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final data = response.data;
      final items = _extractItems(data);
      final total = _extractTotal(data);

      state = state.copyWith(
        isLoading: false,
        products: PaginatedList(
          items: items,
          total: total,
          page: 1,
          perPage: AppConstants.defaultPageSize,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.products.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final nextPage = state.products.nextPage;
      final queryParams = <String, dynamic>{
        'page': nextPage,
        'perPage': AppConstants.defaultPageSize,
      };

      if (state.categoryFilter != null) {
        queryParams['category'] = state.categoryFilter;
      }
      if (state.sortBy != null) {
        queryParams['sortBy'] = state.sortBy;
      }

      final response = await apiClient.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final data = response.data;
      final items = _extractItems(data);
      final total = _extractTotal(data);

      final newPage = PaginatedList<ProductModel>(
        items: items,
        total: total,
        page: nextPage,
        perPage: AppConstants.defaultPageSize,
      );

      state = state.copyWith(
        isLoadingMore: false,
        products: state.products.appendPage(newPage),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setCategory(String? category) {
    state = ProductListState(categoryFilter: category);
    loadProducts();
  }

  void setSort(String? sortBy) {
    state = state.copyWith(sortBy: sortBy);
    loadProducts();
  }

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
    loadProducts();
  }

  List<ProductModel> _extractItems(dynamic data) {
    if (data is Map<String, dynamic>) {
      final d = data['data'];
      if (d is List) {
        return d.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (d is Map<String, dynamic> && d['items'] is List) {
        return (d['items'] as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  int _extractTotal(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['meta'] is Map<String, dynamic>) {
        return (data['meta'] as Map<String, dynamic>)['total'] as int? ?? 0;
      }
      if (data['data'] is Map<String, dynamic>) {
        return (data['data'] as Map<String, dynamic>)['total'] as int? ?? 0;
      }
    }
    return 0;
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier(ref);
});

// Product detail provider
final productDetailProvider =
    FutureProvider.family<ProductModel, String>((ref, productId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.productById(productId));
  final data = response.data['data'] as Map<String, dynamic>;
  return ProductModel.fromJson(data);
});
