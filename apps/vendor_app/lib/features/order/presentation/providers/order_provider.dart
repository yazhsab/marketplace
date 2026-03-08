import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/order_model.dart';

class OrderState {
  final bool isLoading;
  final String? error;
  final List<VendorOrderModel> orders;
  final String? statusFilter;

  const OrderState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.statusFilter,
  });

  OrderState copyWith({
    bool? isLoading,
    String? error,
    List<VendorOrderModel>? orders,
    String? statusFilter,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      orders: orders ?? this.orders,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const OrderState()) {
    loadOrders();
  }

  Future<void> loadOrders({String? statusFilter}) async {
    if (statusFilter != null) {
      state = state.copyWith(statusFilter: statusFilter);
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{};
      if (state.statusFilter != null && state.statusFilter!.isNotEmpty) {
        queryParams['status'] = state.statusFilter;
      }

      final response = await apiClient.get(
        ApiEndpoints.vendorOrders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isLoading: false,
        orders: items
            .map((e) =>
                VendorOrderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.patch(
        ApiEndpoints.vendorOrderStatus(id),
        data: {'status': status},
      );
      await loadOrders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<VendorOrderModel?> getOrderDetail(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response =
          await apiClient.get(ApiEndpoints.vendorOrderById(id));
      return VendorOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});

final orderDetailProvider =
    FutureProvider.family<VendorOrderModel?, String>((ref, id) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.vendorOrderById(id));
  return VendorOrderModel.fromJson(
      response.data['data'] as Map<String, dynamic>);
});
