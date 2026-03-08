import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/paginated_list.dart';
import '../../data/models/order_model.dart';

// Order list state
class OrderListState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final PaginatedList<OrderModel> orders;

  const OrderListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.orders = const PaginatedList(items: [], total: 0, page: 1, perPage: 20),
  });

  OrderListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    PaginatedList<OrderModel>? orders,
  }) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      orders: orders ?? this.orders,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderListState> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const OrderListState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiEndpoints.orders,
        queryParameters: {'page': 1, 'perPage': 20},
      );

      final data = response.data;
      final items = _extractItems(data);
      final total = _extractTotal(data);

      state = state.copyWith(
        isLoading: false,
        orders: PaginatedList(
          items: items,
          total: total,
          page: 1,
          perPage: 20,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.orders.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final nextPage = state.orders.nextPage;
      final response = await apiClient.get(
        ApiEndpoints.orders,
        queryParameters: {'page': nextPage, 'perPage': 20},
      );

      final data = response.data;
      final items = _extractItems(data);
      final total = _extractTotal(data);

      final newPage = PaginatedList<OrderModel>(
        items: items,
        total: total,
        page: nextPage,
        perPage: 20,
      );

      state = state.copyWith(
        isLoadingMore: false,
        orders: state.orders.appendPage(newPage),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    String? paymentId,
    String? notes,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.orders,
        data: {
          'items': items,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          if (paymentId != null) 'paymentId': paymentId,
          if (notes != null) 'notes': notes,
        },
      );
      await loadOrders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.cancelOrder(orderId));
      await loadOrders();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<OrderModel> _extractItems(dynamic data) {
    if (data is Map<String, dynamic>) {
      final d = data['data'];
      if (d is List) {
        return d.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (d is Map<String, dynamic> && d['items'] is List) {
        return (d['items'] as List)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  int _extractTotal(dynamic data) {
    if (data is Map<String, dynamic> && data['meta'] is Map<String, dynamic>) {
      return (data['meta'] as Map<String, dynamic>)['total'] as int? ?? 0;
    }
    return 0;
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderListState>((ref) {
  return OrderNotifier(ref);
});

// Order detail provider
final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, orderId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.orderById(orderId));
  return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
});
