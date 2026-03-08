import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/earnings_model.dart';

class EarningsState {
  final bool isLoading;
  final String? error;
  final EarningsModel? earnings;
  final List<EarningsHistoryItem> history;
  final bool isHistoryLoading;

  const EarningsState({
    this.isLoading = false,
    this.error,
    this.earnings,
    this.history = const [],
    this.isHistoryLoading = false,
  });

  EarningsState copyWith({
    bool? isLoading,
    String? error,
    EarningsModel? earnings,
    List<EarningsHistoryItem>? history,
    bool? isHistoryLoading,
  }) {
    return EarningsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      earnings: earnings ?? this.earnings,
      history: history ?? this.history,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
    );
  }
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  final Ref _ref;

  EarningsNotifier(this._ref) : super(const EarningsState()) {
    loadEarnings();
    loadHistory();
  }

  Future<void> loadEarnings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.deliveryEarnings);
      final earnings = EarningsModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, earnings: earnings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isHistoryLoading: true);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response =
          await apiClient.get(ApiEndpoints.deliveryEarningsHistory);

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isHistoryLoading: false,
        history: items
            .map((e) =>
                EarningsHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isHistoryLoading: false);
    }
  }
}

final earningsProvider =
    StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  return EarningsNotifier(ref);
});
