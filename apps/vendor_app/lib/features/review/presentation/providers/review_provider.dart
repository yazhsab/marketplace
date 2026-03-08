import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/review_model.dart';

class ReviewState {
  final bool isLoading;
  final String? error;
  final List<ReviewModel> reviews;

  const ReviewState({
    this.isLoading = false,
    this.error,
    this.reviews = const [],
  });

  ReviewState copyWith({
    bool? isLoading,
    String? error,
    List<ReviewModel>? reviews,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reviews: reviews ?? this.reviews,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final Ref _ref;

  ReviewNotifier(this._ref) : super(const ReviewState()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.vendorReviews);

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isLoading: false,
        reviews: items
            .map((e) =>
                ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> replyToReview(String id, String reply) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.vendorReviewReply(id),
        data: {'reply': reply},
      );
      await loadReviews();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(ref);
});
