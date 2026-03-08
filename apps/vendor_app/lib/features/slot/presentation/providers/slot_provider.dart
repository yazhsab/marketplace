import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/slot_model.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class SlotState {
  final bool isLoading;
  final String? error;
  final List<SlotModel> slots;

  const SlotState({
    this.isLoading = false,
    this.error,
    this.slots = const [],
  });

  SlotState copyWith({
    bool? isLoading,
    String? error,
    List<SlotModel>? slots,
  }) {
    return SlotState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      slots: slots ?? this.slots,
    );
  }
}

class SlotNotifier extends StateNotifier<SlotState> {
  final Ref _ref;

  SlotNotifier(this._ref) : super(const SlotState()) {
    loadSlots();
  }

  Future<void> loadSlots() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final selectedDate = _ref.read(selectedDateProvider);
      final date =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiEndpoints.vendorSlots,
        queryParameters: {'date': date},
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
        slots: items
            .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSlot(Map<String, dynamic> data) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.vendorSlots, data: data);
      await loadSlots();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSlot(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.delete(ApiEndpoints.vendorSlotById(id));
      await loadSlots();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final slotProvider =
    StateNotifierProvider<SlotNotifier, SlotState>((ref) {
  return SlotNotifier(ref);
});
