import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/assignment_model.dart';
import '../providers/assignment_provider.dart';

class AssignmentListPage extends ConsumerStatefulWidget {
  const AssignmentListPage({super.key});

  @override
  ConsumerState<AssignmentListPage> createState() =>
      _AssignmentListPageState();
}

class _AssignmentListPageState extends ConsumerState<AssignmentListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Active'),
    Tab(text: 'Completed'),
    Tab(text: 'All'),
  ];

  final _statusFilters = [null, 'delivered', null];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == 0) {
      // Active: assigned, accepted, picked_up
      ref
          .read(assignmentListProvider.notifier)
          .loadAssignments(status: 'active');
    } else if (index == 1) {
      ref
          .read(assignmentListProvider.notifier)
          .loadAssignments(status: _statusFilters[index]);
    } else {
      ref.read(assignmentListProvider.notifier).loadAssignments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppTheme.secondary;
      case 'accepted':
        return AppTheme.accent;
      case 'picked_up':
        return AppTheme.primary;
      case 'delivered':
        return AppTheme.successColor;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Assignments',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: theme.textTheme.labelLarge,
              unselectedLabelStyle: theme.textTheme.bodyMedium,
              padding: const EdgeInsets.all(AppTheme.spacingXs),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: AppTheme.spacingBase),
        child: state.isLoading
            ? const LoadingWidget(message: 'Loading assignments...')
            : state.error != null && state.assignments.isEmpty
                ? AppErrorWidget(
                    message: state.error!,
                    onRetry: () => ref
                        .read(assignmentListProvider.notifier)
                        .loadAssignments(),
                  )
                : state.assignments.isEmpty
                    ? const EmptyStateWidget(
                        message: 'No assignments found',
                        icon: Icons.delivery_dining,
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () => ref
                            .read(assignmentListProvider.notifier)
                            .loadAssignments(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingBase),
                          itemCount: state.assignments.length,
                          itemBuilder: (context, index) {
                            return _buildAssignmentCard(
                                context, state.assignments[index]);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildAssignmentCard(
      BuildContext context, AssignmentModel assignment) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(assignment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => context.push('/assignments/${assignment.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            children: [
              // Status accent bar at top
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            assignment.orderNumber ?? 'Order',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            assignment.status.replaceAll('_', ' ').capitalize,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Info rows
                    if (assignment.vendorName != null)
                      _buildInfoRow(
                        Icons.store_outlined,
                        'Pickup: ${assignment.vendorName!}',
                        AppTheme.primary,
                      ),
                    if (assignment.customerName != null)
                      _buildInfoRow(
                        Icons.person_outline,
                        'Deliver to: ${assignment.customerName!}',
                        AppTheme.accent,
                      ),
                    if (assignment.distanceKm != null)
                      _buildInfoRow(
                        Icons.route_outlined,
                        'Distance: ${assignment.distanceKm!.toKm}',
                        AppTheme.textSecondary,
                      ),
                    if (assignment.earnings != null)
                      _buildInfoRow(
                        Icons.currency_rupee,
                        'Earnings: ${assignment.earnings!.toPrice}',
                        AppTheme.successColor,
                      ),

                    const SizedBox(height: AppTheme.spacingSm),
                    Divider(
                        color: AppTheme.border.withValues(alpha: 0.5),
                        height: 1),
                    const SizedBox(height: AppTheme.spacingSm),

                    // Timestamp
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          assignment.createdAt.toTimeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
