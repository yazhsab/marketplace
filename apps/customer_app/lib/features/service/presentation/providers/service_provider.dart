import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/service_model.dart';

final serviceDetailProvider =
    FutureProvider.family<ServiceModel, String>((ref, serviceId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.serviceById(serviceId));
  return ServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
});

// Available slots provider
final serviceSlotsProvider = FutureProvider.family<List<TimeSlot>, ServiceSlotQuery>(
  (ref, query) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(
      ApiEndpoints.serviceSlots(query.serviceId),
      queryParameters: {'date': query.date},
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

class ServiceSlotQuery {
  final String serviceId;
  final String date;

  const ServiceSlotQuery({required this.serviceId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceSlotQuery &&
          serviceId == other.serviceId &&
          date == other.date;

  @override
  int get hashCode => serviceId.hashCode ^ date.hashCode;
}

class TimeSlot {
  final String id;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}
