import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/booking_model.dart';

class BookingState {
  final bool isLoading;
  final String? error;
  final List<VendorBookingModel> bookings;

  const BookingState({
    this.isLoading = false,
    this.error,
    this.bookings = const [],
  });

  BookingState copyWith({
    bool? isLoading,
    String? error,
    List<VendorBookingModel>? bookings,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookings: bookings ?? this.bookings,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final Ref _ref;

  BookingNotifier(this._ref) : super(const BookingState()) {
    loadBookings();
  }

  Future<void> loadBookings({String? filter}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{};
      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }

      final response = await apiClient.get(
        ApiEndpoints.vendorBookings,
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
        bookings: items
            .map((e) =>
                VendorBookingModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBookingStatus(String id, String status) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.patch(
        ApiEndpoints.vendorBookingStatus(id),
        data: {'status': status},
      );
      await loadBookings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref);
});

final bookingDetailProvider =
    FutureProvider.family<VendorBookingModel?, String>((ref, id) async {
  final apiClient = ref.read(apiClientProvider);
  final response =
      await apiClient.get(ApiEndpoints.vendorBookingById(id));
  return VendorBookingModel.fromJson(
      response.data['data'] as Map<String, dynamic>);
});
