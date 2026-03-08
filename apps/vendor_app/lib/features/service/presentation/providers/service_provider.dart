import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/service_model.dart';

class ServiceState {
  final bool isLoading;
  final String? error;
  final List<ServiceModel> services;
  final bool isSubmitting;

  const ServiceState({
    this.isLoading = false,
    this.error,
    this.services = const [],
    this.isSubmitting = false,
  });

  ServiceState copyWith({
    bool? isLoading,
    String? error,
    List<ServiceModel>? services,
    bool? isSubmitting,
  }) {
    return ServiceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      services: services ?? this.services,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ServiceNotifier extends StateNotifier<ServiceState> {
  final Ref _ref;

  ServiceNotifier(this._ref) : super(const ServiceState()) {
    loadServices();
  }

  Future<void> loadServices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.vendorServices);

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isLoading: false,
        services: items
            .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ServiceModel?> createService(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiEndpoints.vendorServices,
        data: data,
      );
      final service = ServiceModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      await loadServices();
      state = state.copyWith(isSubmitting: false);
      return service;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  Future<ServiceModel?> updateService(
      String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.put(
        ApiEndpoints.vendorServiceById(id),
        data: data,
      );
      final service = ServiceModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      await loadServices();
      state = state.copyWith(isSubmitting: false);
      return service;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  Future<void> deleteService(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.delete(ApiEndpoints.vendorServiceById(id));
      await loadServices();
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

final serviceProvider =
    StateNotifierProvider<ServiceNotifier, ServiceState>((ref) {
  return ServiceNotifier(ref);
});

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategoryModel>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.serviceCategories);
  final data = response.data['data'];
  List<dynamic> items = data is List ? data : (data['items'] ?? []);
  return items
      .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ServiceCategoryModel {
  final String id;
  final String name;
  final String? icon;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}
