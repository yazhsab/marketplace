import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> {
  final _scrollController = ScrollController();
  String _selectedFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'active', 'label': 'Active'},
    {'key': 'completed', 'label': 'Completed'},
    {'key': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (_selectedFilter) {
      case 'active':
        return orders
            .where((o) => [
                  'pending',
                  'confirmed',
                  'processing',
                  'shipped',
                  'out_for_delivery'
                ].contains(o.status))
            .toList();
      case 'completed':
        return orders.where((o) => o.status == 'delivered').toList();
      case 'cancelled':
        return orders
            .where((o) => o.status == 'cancelled' || o.status == 'refunded')
            .toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('My Orders', style: theme.textTheme.titleLarge),
      ),
      body: state.isLoading
          ? Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Column(
                children: List.generate(
                  5,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
                    child: SkeletonListTile(),
                  ),
                ),
              ),
            )
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(orderProvider.notifier).loadOrders(),
                )
              : state.orders.items.isEmpty
                  ? const EmptyStateWidget(
                      message:
                          'No orders yet.\nStart shopping to place your first order!',
                      icon: Icons.receipt_long_outlined,
                    )
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () =>
                          ref.read(orderProvider.notifier).loadOrders(),
                      child: Column(
                        children: [
                          // Filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingBase,
                              vertical: AppTheme.spacingMd,
                            ),
                            child: Row(
                              children: _filters.map((filter) {
                                final isSelected =
                                    _selectedFilter == filter['key'];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppTheme.spacingSm),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter =
                                            filter['key'] as String;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingBase,
                                        vertical: AppTheme.spacingSm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.card,
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppTheme.radiusFull),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.border,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.primary
                                                      .withValues(
                                                          alpha: 0.25),
                                                  blurRadius: 8,
                                                  offset:
                                                      const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        filter['label'] as String,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Order list
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final filteredOrders = _filterOrders(
                                    state.orders.items);
                                if (filteredOrders.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppTheme.spacing2xl),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.search_off_rounded,
                                              size: 28,
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppTheme.spacingBase),
                                          Text(
                                            'No orders found',
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppTheme.spacingXs),
                                          Text(
                                            'Try a different filter',
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppTheme.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingBase,
                                  ),
                                  itemCount: filteredOrders.length +
                                      (state.isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= filteredOrders.length) {
                                      return const Padding(
                                        padding: EdgeInsets.all(
                                            AppTheme.spacingBase),
                                        child: SkeletonListTile(),
                                      );
                                    }
                                    return _OrderCard(
                                        order: filteredOrders[index]);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'shipped':
      case 'out_for_delivery':
        return AppTheme.primary;
      case 'delivered':
        return AppTheme.secondary;
      case 'cancelled':
        return AppTheme.error;
      case 'refunded':
        return AppTheme.textTertiary;
      default:
        return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(order.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: GestureDetector(
        onTap: () => context.push('/orders/${order.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Row(
            children: [
              // Order content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order number + status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${order.orderNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                order.statusDisplay,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),

                    // Item count
                    Text(
                      '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Total + date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.total.toPrice,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (order.createdAt != null)
                          Text(
                            order.createdAt!.toFormattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron right
              Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
