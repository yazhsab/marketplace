import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Pending'),
    Tab(text: 'Active'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
  ];

  final _statusFilters = [
    'pending',
    'confirmed,preparing,ready,out_for_delivery',
    'delivered,completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref
        .read(orderProvider.notifier)
        .loadOrders(statusFilter: _statusFilters[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Orders', style: theme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
                vertical: AppTheme.spacingSm),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: AppTheme.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelMedium,
                dividerColor: Colors.transparent,
                tabs: _tabs,
              ),
            ),
          ),
        ),
      ),
      body: orderState.isLoading
          ? const LoadingWidget(message: 'Loading orders...')
          : orderState.error != null
              ? AppErrorWidget(
                  message: orderState.error!,
                  onRetry: () =>
                      ref.read(orderProvider.notifier).loadOrders(),
                )
              : orderState.orders.isEmpty
                  ? const EmptyStateWidget(
                      message: 'No orders found',
                      icon: Icons.receipt_long_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(orderProvider.notifier).loadOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        itemCount: orderState.orders.length,
                        itemBuilder: (context, index) => _buildOrderCard(
                            context, ref, orderState.orders[index]),
                      ),
                    ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, WidgetRef ref, VendorOrderModel order) {
    final theme = Theme.of(context);

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
        child: InkWell(
          onTap: () => context.push('/orders/${order.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: order number + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Customer + time row
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 16, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      order.createdAt.toTimeAgo,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Divider
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: AppTheme.spacingSm),

                // Items count + total
                Row(
                  children: [
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      order.totalAmount.toPrice,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),

                // Action buttons for pending orders
                if (order.canConfirm) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(orderProvider.notifier)
                              .updateOrderStatus(order.id, 'cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref
                              .read(orderProvider.notifier)
                              .updateOrderStatus(order.id, 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
