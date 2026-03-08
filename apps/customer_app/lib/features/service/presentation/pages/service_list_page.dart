import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/service_card.dart';
import '../../data/models/service_model.dart';

final serviceListProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.services);
  final data = response.data['data'];
  List<dynamic> items = [];
  if (data is List) {
    items = data;
  } else if (data is Map<String, dynamic> && data['items'] is List) {
    items = data['items'] as List;
  }
  return items
      .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ServiceListPage extends ConsumerWidget {
  final String? category;

  const ServiceListPage({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
      ),
      body: servicesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(serviceListProvider),
        ),
        data: (services) {
          final filteredServices = category != null
              ? services.where((s) => s.category == category).toList()
              : services;

          if (filteredServices.isEmpty) {
            return const EmptyStateWidget(
              message: 'No services available',
              icon: Icons.handyman_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredServices.length,
            itemBuilder: (context, index) {
              final service = filteredServices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ServiceCard(
                    id: service.id,
                    name: service.name,
                    price: service.price,
                    durationMinutes: service.durationMinutes,
                    imageUrl:
                        service.images.isNotEmpty ? service.images.first : null,
                    rating: service.rating,
                    reviewCount: service.reviewCount,
                    vendorName: service.vendorName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
