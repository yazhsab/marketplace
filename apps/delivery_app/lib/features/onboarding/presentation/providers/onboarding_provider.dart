import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/delivery_partner_model.dart';

class OnboardingState {
  final bool isLoading;
  final String? error;
  final bool isRegistered;
  final DeliveryPartnerModel? partner;

  const OnboardingState({
    this.isLoading = false,
    this.error,
    this.isRegistered = false,
    this.partner,
  });

  OnboardingState copyWith({
    bool? isLoading,
    String? error,
    bool? isRegistered,
    DeliveryPartnerModel? partner,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRegistered: isRegistered ?? this.isRegistered,
      partner: partner ?? this.partner,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState());

  Future<void> register({
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
    String? zonePreference,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiEndpoints.deliveryRegister,
        data: {
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber,
          'license_number': licenseNumber,
          if (zonePreference != null) 'zone_preference': zonePreference,
        },
      );
      final partner = DeliveryPartnerModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        isRegistered: true,
        partner: partner,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});
