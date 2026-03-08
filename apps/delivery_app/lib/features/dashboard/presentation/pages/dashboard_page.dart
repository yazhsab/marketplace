import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              onPressed: () => context.push('/notifications'),
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      body: dashState.isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : dashState.error != null && dashState.partner == null
              ? AppErrorWidget(
                  message: dashState.error!,
                  onRetry: () =>
                      ref.read(dashboardProvider.notifier).loadDashboard(),
                )
              : dashState.partner == null
                  ? const LoadingWidget()
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () =>
                          ref.read(dashboardProvider.notifier).loadDashboard(),
                      child: ListView(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        children: [
                          // -- Status Card with Gradient --
                          _buildStatusCard(context, ref, dashState),
                          const SizedBox(height: AppTheme.spacingBase),

                          // -- Toggle Cards Side by Side --
                          Row(
                            children: [
                              Expanded(
                                child: _buildShiftToggle(
                                    context, ref, dashState),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: _buildAvailabilityToggle(
                                    context, ref, dashState),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingBase),

                          // -- Active Assignment Banner --
                          if (dashState.partner!.hasActiveOrder) ...[
                            _buildActiveAssignmentCard(context),
                            const SizedBox(height: AppTheme.spacingBase),
                          ],

                          // -- Today's Stats --
                          if (dashState.todayStats.isNotEmpty) ...[
                            Text(
                              "Today's Stats",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            _buildTodayStatsRow(context, dashState),
                            const SizedBox(height: AppTheme.spacingXl),
                          ],

                          // -- Performance Card --
                          _buildPerformanceCard(context, dashState),
                          const SizedBox(height: AppTheme.spacingBase),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, WidgetRef ref, DashboardState dashState) {
    final partner = dashState.partner!;
    final theme = Theme.of(context);

    IconData vehicleIcon;
    switch (partner.vehicleType.toLowerCase()) {
      case 'car':
        vehicleIcon = Icons.directions_car;
        break;
      case 'bicycle':
        vehicleIcon = Icons.pedal_bike;
        break;
      case 'scooter':
        vehicleIcon = Icons.electric_scooter;
        break;
      default:
        vehicleIcon = Icons.two_wheeler;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(vehicleIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.vehicleType.capitalize,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (partner.vehicleNumber != null)
                  Text(
                    partner.vehicleNumber!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          // Active Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: partner.status == 'active' || partner.status == 'approved'
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: partner.status == 'active' ||
                            partner.status == 'approved'
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  partner.status.capitalize,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftToggle(
      BuildContext context, WidgetRef ref, DashboardState dashState) {
    final isOnShift = dashState.partner!.isOnShift;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isOnShift
              ? AppTheme.onlineColor.withValues(alpha: 0.3)
              : AppTheme.border,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOnShift
                      ? AppTheme.onlineColor.withValues(alpha: 0.1)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  isOnShift ? Icons.work : Icons.work_off,
                  size: 18,
                  color:
                      isOnShift ? AppTheme.onlineColor : AppTheme.offlineColor,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isOnShift,
                  onChanged: dashState.partner!.isApproved
                      ? (_) =>
                          ref.read(dashboardProvider.notifier).toggleShift()
                      : null,
                  activeColor: AppTheme.onlineColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isOnShift ? 'On Shift' : 'Off Shift',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isOnShift ? 'Currently on duty' : 'Start your shift',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle(
      BuildContext context, WidgetRef ref, DashboardState dashState) {
    final isAvailable = dashState.partner!.isAvailable;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isAvailable
              ? AppTheme.accent.withValues(alpha: 0.3)
              : AppTheme.border,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppTheme.accent.withValues(alpha: 0.1)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color:
                      isAvailable ? AppTheme.accent : AppTheme.offlineColor,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isAvailable,
                  onChanged: dashState.partner!.isOnShift
                      ? (_) => ref
                          .read(dashboardProvider.notifier)
                          .toggleAvailability()
                      : null,
                  activeColor: AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isAvailable ? 'Available' : 'Unavailable',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isAvailable ? 'Ready for orders' : 'Not accepting',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssignmentCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/assignments'),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.delivery_dining,
                      color: AppTheme.warningColor, size: 22),
                  // Pulsing dot
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.warningColor.withValues(alpha: 0.08),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Delivery',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'You have an active assignment',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.warningColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatsRow(BuildContext context, DashboardState dashState) {
    final stats = dashState.todayStats;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            theme,
            icon: Icons.delivery_dining,
            label: 'Deliveries',
            value: '${stats['today_deliveries'] ?? 0}',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _buildMiniStat(
            theme,
            icon: Icons.currency_rupee,
            label: 'Earnings',
            value:
                ((stats['today_earnings'] as num?)?.toDouble() ?? 0).toPrice,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _buildMiniStat(
            theme,
            icon: Icons.route,
            label: 'Distance',
            value:
                '${((stats['today_distance'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km',
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
      BuildContext context, DashboardState dashState) {
    final partner = dashState.partner!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.trending_up,
                    size: 18, color: AppTheme.secondary),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Rating Stars
          Row(
            children: [
              ...List.generate(5, (index) {
                final rating = partner.avgRating;
                if (index < rating.floor()) {
                  return const Icon(Icons.star,
                      color: AppTheme.secondary, size: 24);
                } else if (index < rating) {
                  return const Icon(Icons.star_half,
                      color: AppTheme.secondary, size: 24);
                } else {
                  return Icon(Icons.star_outline,
                      color: AppTheme.textTertiary.withValues(alpha: 0.5),
                      size: 24);
                }
              }),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                partner.avgRating.toStringAsFixed(1),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),

          const Divider(color: AppTheme.border),
          const SizedBox(height: AppTheme.spacingBase),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildPerformanceStat(
                  theme,
                  label: 'Total Deliveries',
                  value: '${partner.totalDeliveries}',
                  onTap: () => context.go('/assignments'),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.border,
              ),
              Expanded(
                child: _buildPerformanceStat(
                  theme,
                  label: 'Total Earnings',
                  value: partner.totalEarnings.toPrice,
                  onTap: () => context.go('/earnings'),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.border,
              ),
              Expanded(
                child: _buildPerformanceStat(
                  theme,
                  label: 'Commission',
                  value:
                      '${partner.commissionPct.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(
    ThemeData theme, {
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
