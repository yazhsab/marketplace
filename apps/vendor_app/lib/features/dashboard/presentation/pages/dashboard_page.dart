import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: dashState.isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : dashState.error != null
              ? AppErrorWidget(
                  message: dashState.error!,
                  onRetry: () =>
                      ref.read(dashboardProvider.notifier).fetchStats(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(dashboardProvider.notifier).fetchStats(),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Gradient header with greeting + online toggle
                      _buildHeader(context, ref, dashState, theme),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingBase),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.spacingLg),

                            // Revenue Card -- gradient
                            _buildRevenueCard(context, dashState, theme),
                            const SizedBox(height: AppTheme.spacingLg),

                            // Stats Grid -- 2x2
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: AppTheme.spacingMd,
                              crossAxisSpacing: AppTheme.spacingMd,
                              childAspectRatio: 1.4,
                              children: [
                                StatCard(
                                  icon: Icons.shopping_bag_outlined,
                                  label: "Today's Orders",
                                  value: '${dashState.todayOrders}',
                                  iconColor: AppTheme.primary,
                                  onTap: () => context.go('/orders'),
                                ),
                                StatCard(
                                  icon: Icons.calendar_today_outlined,
                                  label: "Today's Bookings",
                                  value: '${dashState.todayBookings}',
                                  iconColor: AppTheme.secondary,
                                  onTap: () => context.go('/bookings'),
                                ),
                                StatCard(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Wallet Balance',
                                  value: dashState.walletBalance.toPrice,
                                  iconColor: AppTheme.successColor,
                                  onTap: () => context.go('/wallet'),
                                ),
                                StatCard(
                                  icon: Icons.star_outline_rounded,
                                  label: 'Rating',
                                  value: '4.8',
                                  iconColor: AppTheme.warningColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingXl),

                            // Quick Actions
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            SizedBox(
                              height: 44,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildActionChip(
                                    context,
                                    Icons.add_circle_outline_rounded,
                                    'Add Product',
                                    () => context.push('/products/add'),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  _buildActionChip(
                                    context,
                                    Icons.inventory_2_outlined,
                                    'Products',
                                    () => context.go('/products'),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  _buildActionChip(
                                    context,
                                    Icons.receipt_long_outlined,
                                    'Orders',
                                    () => context.go('/orders'),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  _buildActionChip(
                                    context,
                                    Icons.calendar_month_outlined,
                                    'Bookings',
                                    () => context.go('/bookings'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXl),

                            // Recent Orders
                            _buildSectionHeader(
                              context,
                              'Recent Orders',
                              () => context.go('/orders'),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            if (dashState.recentOrders.isEmpty)
                              _buildEmptySection(context, 'No recent orders')
                            else
                              ...dashState.recentOrders
                                  .map((order) =>
                                      _buildOrderCard(context, order)),

                            const SizedBox(height: AppTheme.spacingXl),

                            // Recent Bookings
                            _buildSectionHeader(
                              context,
                              'Recent Bookings',
                              () => context.go('/bookings'),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            if (dashState.recentBookings.isEmpty)
                              _buildEmptySection(context, 'No recent bookings')
                            else
                              ...dashState.recentBookings
                                  .map((booking) =>
                                      _buildBookingCard(context, booking)),
                            const SizedBox(height: AppTheme.spacing2xl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic dashState,
      ThemeData theme) {
    final isOnline = dashState.isOnline as bool;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        MediaQuery.of(context).padding.top + AppTheme.spacingBase,
        AppTheme.spacingBase,
        AppTheme.spacingLg,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()},',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      dashState.businessName as String? ?? 'Vendor',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Online/Offline toggle pill
          GestureDetector(
            onTap: () =>
                ref.read(dashboardProvider.notifier).toggleOnlineStatus(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? AppTheme.onlineColor
                          : AppTheme.offlineColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  SizedBox(
                    height: 20,
                    child: Switch(
                      value: isOnline,
                      onChanged: (_) => ref
                          .read(dashboardProvider.notifier)
                          .toggleOnlineStatus(),
                      activeColor: AppTheme.onlineColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
      BuildContext context, dynamic dashState, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee_rounded,
                  color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Total Revenue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            (dashState.totalRevenue as num).toDouble().toPrice,
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              'Lifetime earnings',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase, vertical: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View All',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing2xl),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.push('/orders/${order['_id'] ?? order['id']}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.receipt_outlined,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order['orderNumber'] ?? ''}',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order['customerName'] as String? ?? 'Customer',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (order['totalAmount'] as num?)?.currencyFormat ?? '',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    StatusBadge(
                        status: order['status'] as String? ?? 'pending'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, Map<String, dynamic> booking) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context
              .push('/bookings/${booking['_id'] ?? booking['id']}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.secondary, size: 20),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['serviceName'] as String? ?? 'Service',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking['customerName'] as String? ?? 'Customer',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                    status: booking['status'] as String? ?? 'pending'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
