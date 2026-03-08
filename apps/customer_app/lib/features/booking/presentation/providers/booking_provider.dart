import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/booking_model.dart';

class BookingListState {
  final bool isLoading;
  final String? error;
  final List<BookingModel> bookings;

  const BookingListState({
    this.isLoading = false,
    this.error,
    this.bookings = const [],
  });

  BookingListState copyWith({
    bool? isLoading,
    String? error,
    List<BookingModel>? bookings,
  }) {
    return BookingListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookings: bookings ?? this.bookings,
    );
  }

  List<BookingModel> get upcomingBookings =>
      bookings.where((b) => b.isUpcoming).toList();

  List<BookingModel> get pastBookings =>
      bookings.where((b) => !b.isUpcoming).toList();
}

class BookingNotifier extends StateNotifier<BookingListState> {
  final Ref _ref;

  BookingNotifier(this._ref) : super(const BookingListState()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.bookings);

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
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createBooking({
    required String serviceId,
    required String scheduledDate,
    required String startTime,
    required String endTime,
    required String paymentMethod,
    String? notes,
    Map<String, dynamic>? address,
    String? paymentId,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.bookings,
        data: {
          'serviceId': serviceId,
          'scheduledDate': scheduledDate,
          'startTime': startTime,
          'endTime': endTime,
          'paymentMethod': paymentMethod,
          if (notes != null) 'notes': notes,
          if (address != null) 'address': address,
          if (paymentId != null) 'paymentId': paymentId,
        },
      );
      await loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.cancelBooking(bookingId));
      await loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, BookingListState>((ref) {
  return BookingNotifier(ref);
});

// Booking detail provider
final bookingDetailProvider =
    FutureProvider.family<BookingModel, String>((ref, bookingId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.bookingById(bookingId));
  return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
});
