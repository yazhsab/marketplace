import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';

class DashboardState {
  final bool isLoading;
  final String? error;
  final int todayOrders;
  final int todayBookings;
  final double walletBalance;
  final double totalRevenue;
  final bool isOnline;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> recentBookings;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.todayOrders = 0,
    this.todayBookings = 0,
    this.walletBalance = 0,
    this.totalRevenue = 0,
    this.isOnline = false,
    this.recentOrders = const [],
    this.recentBookings = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    int? todayOrders,
    int? todayBookings,
    double? walletBalance,
    double? totalRevenue,
    bool? isOnline,
    List<Map<String, dynamic>>? recentOrders,
    List<Map<String, dynamic>>? recentBookings,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todayOrders: todayOrders ?? this.todayOrders,
      todayBookings: todayBookings ?? this.todayBookings,
      walletBalance: walletBalance ?? this.walletBalance,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isOnline: isOnline ?? this.isOnline,
      recentOrders: recentOrders ?? this.recentOrders,
      recentBookings: recentBookings ?? this.recentBookings,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardState()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.vendorDashboard);
      final data = response.data['data'] as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        todayOrders: data['todayOrders'] as int? ?? 0,
        todayBookings: data['todayBookings'] as int? ?? 0,
        walletBalance: (data['walletBalance'] as num?)?.toDouble() ?? 0,
        totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0,
        isOnline: data['isOnline'] as bool? ?? false,
        recentOrders: (data['recentOrders'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        recentBookings: (data['recentBookings'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleOnlineStatus() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response =
          await apiClient.post(ApiEndpoints.vendorToggleOnline);
      final isOnline =
          response.data['data']?['isOnline'] as bool? ?? !state.isOnline;
      state = state.copyWith(isOnline: isOnline);
    } catch (_) {
      // Keep current state on error
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
