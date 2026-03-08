import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../onboarding/data/models/delivery_partner_model.dart';

class DashboardState {
  final bool isLoading;
  final String? error;
  final DeliveryPartnerModel? partner;
  final Map<String, dynamic> todayStats;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.partner,
    this.todayStats = const {},
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DeliveryPartnerModel? partner,
    Map<String, dynamic>? todayStats,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      partner: partner ?? this.partner,
      todayStats: todayStats ?? this.todayStats,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);

      // Load profile
      final profileRes = await apiClient.get(ApiEndpoints.deliveryProfile);
      final partner = DeliveryPartnerModel.fromJson(
          profileRes.data['data'] as Map<String, dynamic>);

      // Load stats
      Map<String, dynamic> stats = {};
      try {
        final statsRes = await apiClient.get(ApiEndpoints.deliveryStats);
        stats = statsRes.data['data'] as Map<String, dynamic>? ?? {};
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        partner: partner,
        todayStats: stats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleAvailability() async {
    final partner = state.partner;
    if (partner == null) return;

    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(
        ApiEndpoints.deliveryAvailability,
        data: {'is_available': !partner.isAvailable},
      );
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> toggleShift() async {
    final partner = state.partner;
    if (partner == null) return;

    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(
        ApiEndpoints.deliveryShift,
        data: {'is_on_shift': !partner.isOnShift},
      );
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(
        ApiEndpoints.deliveryUpdateLocation,
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (_) {}
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
