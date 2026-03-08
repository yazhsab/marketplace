import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../data/models/service_model.dart';
import '../providers/service_provider.dart';

class ServiceListPage extends ConsumerStatefulWidget {
  const ServiceListPage({super.key});

  @override
  ConsumerState<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends ConsumerState<ServiceListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceModel> _filterServices(List<ServiceModel> services) {
    if (_searchQuery.isEmpty) return services;
    final query = _searchQuery.toLowerCase();
    return services
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            (s.categoryName?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(serviceProvider.notifier).loadServices(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/services/add'),
        child: const Icon(Icons.add),
      ),
      body: serviceState.isLoading
          ? _buildSkeletonLoading()
          : serviceState.error != null
              ? AppErrorWidget(
                  message: serviceState.error!,
                  onRetry: () =>
                      ref.read(serviceProvider.notifier).loadServices(),
                )
              : serviceState.services.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(serviceProvider.notifier).loadServices(),
                      child: Column(
                        children: [
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spacingBase,
                              AppTheme.spacingSm,
                              AppTheme.spacingBase,
                              AppTheme.spacingMd,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search services...',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.textTertiary,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 18,
                                              color: AppTheme.textTertiary),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(
                                                () => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingBase,
                                    vertical: AppTheme.spacingMd,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Services list
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final filtered = _filterServices(
                                    serviceState.services);
                                if (filtered.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            size: 48,
                                            color: AppTheme.textTertiary),
                                        const SizedBox(
                                            height: AppTheme.spacingMd),
                                        Text(
                                          'No services match your search',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.textTertiary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingBase),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildServiceCard(
                                          context, ref, filtered[index]),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              'No services yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Add your first service to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/services/add'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Service'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context, WidgetRef ref, ServiceModel service) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => context.push('/services/${service.id}/edit'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                // Service Image
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                  child: CachedImage(
                    imageUrl: service.images.isNotEmpty
                        ? service.images.first
                        : null,
                    width: 80,
                    height: 80,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),

                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull),
                        ),
                        child: Text(
                          service.price.toPrice,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: AppTheme.spacingXs),
                          Text(
                            service.formattedDuration,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          if (service.categoryName != null) ...[
                            const SizedBox(width: AppTheme.spacingMd),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppTheme.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Flexible(
                              child: Text(
                                service.categoryName!,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Popup menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: AppTheme.textTertiary),
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/services/${service.id}/edit');
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, ref, service);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: AppTheme.spacingSm),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppTheme.error),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text('Delete',
                              style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              _shimmerBox(width: 80, height: 80, radius: AppTheme.radiusMd),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 160, height: 16),
                    const SizedBox(height: AppTheme.spacingSm),
                    _shimmerBox(
                        width: 80,
                        height: 22,
                        radius: AppTheme.radiusFull),
                    const SizedBox(height: AppTheme.spacingSm),
                    _shimmerBox(width: 120, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content:
            Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(serviceProvider.notifier).deleteService(service.id);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
