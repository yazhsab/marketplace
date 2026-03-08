import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/product_model.dart';

class ProductState {
  final bool isLoading;
  final String? error;
  final List<ProductModel> products;
  final bool isSubmitting;

  const ProductState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.isSubmitting = false,
  });

  ProductState copyWith({
    bool? isLoading,
    String? error,
    List<ProductModel>? products,
    bool? isSubmitting,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      products: products ?? this.products,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final Ref _ref;

  ProductNotifier(this._ref) : super(const ProductState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.vendorProducts);

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isLoading: false,
        products: items
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ProductModel?> createProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiEndpoints.vendorProducts,
        data: data,
      );
      final product = ProductModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      await loadProducts();
      state = state.copyWith(isSubmitting: false);
      return product;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  Future<ProductModel?> updateProduct(
      String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.put(
        ApiEndpoints.vendorProductById(id),
        data: data,
      );
      final product = ProductModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      await loadProducts();
      state = state.copyWith(isSubmitting: false);
      return product;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.delete(ApiEndpoints.vendorProductById(id));
      await loadProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateStock(String id, int quantity) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.patch(
        ApiEndpoints.vendorProductStock(id),
        data: {'stock': quantity},
      );
      await loadProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<String>> uploadImages(List<String> filePaths) async {
    final apiClient = _ref.read(apiClientProvider);
    final urls = <String>[];
    for (final path in filePaths) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
      });
      final response = await apiClient.uploadFile(
        ApiEndpoints.uploadMedia,
        formData: formData,
      );
      final url = response.data['data']?['url'] as String?;
      if (url != null) urls.add(url);
    }
    return urls;
  }
}

final productProvider =
    StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.productCategories);
  final data = response.data['data'];
  List<dynamic> items = data is List ? data : (data['items'] ?? []);
  return items
      .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
