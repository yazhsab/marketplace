import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/assignment_model.dart';

class AssignmentListState {
  final bool isLoading;
  final String? error;
  final List<AssignmentModel> assignments;
  final String? statusFilter;

  const AssignmentListState({
    this.isLoading = false,
    this.error,
    this.assignments = const [],
    this.statusFilter,
  });

  AssignmentListState copyWith({
    bool? isLoading,
    String? error,
    List<AssignmentModel>? assignments,
    String? statusFilter,
  }) {
    return AssignmentListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      assignments: assignments ?? this.assignments,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AssignmentListNotifier extends StateNotifier<AssignmentListState> {
  final Ref _ref;

  AssignmentListNotifier(this._ref) : super(const AssignmentListState()) {
    loadAssignments();
  }

  Future<void> loadAssignments({String? status}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: status);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await apiClient.get(
        ApiEndpoints.deliveryAssignments,
        queryParameters: queryParams,
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
        assignments: items
            .map((e) =>
                AssignmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> acceptAssignment(String assignmentId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.acceptAssignment(assignmentId));
      await loadAssignments(status: state.statusFilter);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectAssignment(String assignmentId, {String? reason}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.rejectAssignment(assignmentId),
        data: reason != null ? {'reason': reason} : null,
      );
      await loadAssignments(status: state.statusFilter);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> pickupOrder(String assignmentId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.pickupAssignment(assignmentId));
      await loadAssignments(status: state.statusFilter);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deliverOrder(
    String assignmentId, {
    required String otp,
    String? proofUrl,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.deliverAssignment(assignmentId),
        data: {
          'otp': otp,
          if (proofUrl != null) 'proof_url': proofUrl,
        },
      );
      await loadAssignments(status: state.statusFilter);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final assignmentListProvider =
    StateNotifierProvider<AssignmentListNotifier, AssignmentListState>((ref) {
  return AssignmentListNotifier(ref);
});
