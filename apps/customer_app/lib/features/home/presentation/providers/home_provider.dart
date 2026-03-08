import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../product/data/models/product_model.dart';
import '../../../service/data/models/service_model.dart';

// Category model
class Category {
  final String id;
  final String name;
  final String? icon;

  const Category({required this.id, required this.name, this.icon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}

// Vendor summary model
class VendorSummary {
  final String id;
  final String businessName;
  final String? logoUrl;
  final double rating;
  final String? category;
  final double? distance;

  const VendorSummary({
    required this.id,
    required this.businessName,
    this.logoUrl,
    this.rating = 0,
    this.category,
    this.distance,
  });

  factory VendorSummary.fromJson(Map<String, dynamic> json) {
    return VendorSummary(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? json['logo'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }
}

// Home state
class HomeState {
  final bool isLoading;
  final String? error;
  final List<Category> categories;
  final List<VendorSummary> nearbyVendors;
  final List<ProductModel> popularProducts;
  final List<ServiceModel> topServices;

  const HomeState({
    this.isLoading = false,
    this.error,
    this.categories = const [],
    this.nearbyVendors = const [],
    this.popularProducts = const [],
    this.topServices = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    List<Category>? categories,
    List<VendorSummary>? nearbyVendors,
    List<ProductModel>? popularProducts,
    List<ServiceModel>? topServices,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categories: categories ?? this.categories,
      nearbyVendors: nearbyVendors ?? this.nearbyVendors,
      popularProducts: popularProducts ?? this.popularProducts,
      topServices: topServices ?? this.topServices,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;

  HomeNotifier(this._ref) : super(const HomeState()) {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);

      // Fetch all data in parallel
      final results = await Future.wait([
        apiClient.get(ApiEndpoints.productCategories).catchError((_) => _emptyResponse()),
        apiClient.get(ApiEndpoints.nearbyVendors).catchError((_) => _emptyResponse()),
        apiClient.get(ApiEndpoints.popularProducts).catchError((_) => _emptyResponse()),
        apiClient.get(ApiEndpoints.topServices).catchError((_) => _emptyResponse()),
      ]);

      final categoriesData = _extractList(results[0].data);
      final vendorsData = _extractList(results[1].data);
      final productsData = _extractList(results[2].data);
      final servicesData = _extractList(results[3].data);

      state = state.copyWith(
        isLoading: false,
        categories: categoriesData.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList(),
        nearbyVendors: vendorsData.map((e) => VendorSummary.fromJson(e as Map<String, dynamic>)).toList(),
        popularProducts: productsData.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
        topServices: servicesData.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  dynamic _emptyResponse() {
    return _FakeResponse();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is _FakeResponse) return [];
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'] as List;
      if (data['data'] is Map && data['data']['items'] is List) {
        return data['data']['items'] as List;
      }
    }
    if (data is List) return data;
    return [];
  }
}

class _FakeResponse {
  dynamic get data => <String, dynamic>{'data': <dynamic>[]};
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});
