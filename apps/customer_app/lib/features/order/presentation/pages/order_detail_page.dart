import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/order_provider.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  static const _statusSteps = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Order Details', style: theme.textTheme.titleLarge),
      ),
      body: orderAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            children: [
              const SkeletonCard(height: 80),
              const SizedBox(height: AppTheme.spacingBase),
              const SkeletonCard(height: 100),
              const SizedBox(height: AppTheme.spacingBase),
              ...List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: SkeletonListTile(),
                ),
              ),
              const SizedBox(height: AppTheme.spacingBase),
              const SkeletonCard(height: 120),
            ],
          ),
        ),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) {
          final currentStepIndex = _statusSteps.indexOf(order.status);
          final isCancelled =
              order.status == 'cancelled' || order.status == 'refunded';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingBase),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Order #${order.orderNumber}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          _StatusBadge(
                              status: order.status,
                              label: order.statusDisplay),
                        ],
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              'Placed on ${order.createdAt!.toFormattedDateTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Horizontal Status Timeline
                if (!isCancelled) ...[
                  Text(
                    'Order Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Column(
                      children: [
                        // Horizontal dots + lines
                        Row(
                          children: List.generate(
                            _statusSteps.length * 2 - 1,
                            (index) {
                              if (index.isEven) {
                                final stepIndex = index ~/ 2;
                                final isCompleted =
                                    stepIndex <= currentStepIndex;
                                final isCurrent =
                                    stepIndex == currentStepIndex;
                                return Container(
                                  width: isCurrent ? 22 : 16,
                                  height: isCurrent ? 22 : 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                    border: isCurrent
                                        ? Border.all(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.3),
                                            width: 3,
                                          )
                                        : null,
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isCompleted && !isCurrent
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        )
                                      : null,
                                );
                              } else {
                                final lineStepIndex = (index - 1) ~/ 2;
                                final isCompleted =
                                    lineStepIndex < currentStepIndex;
                                return Expanded(
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        // Step labels
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: _statusSteps.map((step) {
                            final stepIndex =
                                _statusSteps.indexOf(step);
                            final isCompleted =
                                stepIndex <= currentStepIndex;
                            final isCurrent =
                                stepIndex == currentStepIndex;
                            return SizedBox(
                              width: 52,
                              child: Text(
                                _getStepLabel(step),
                                textAlign: TextAlign.center,
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isCompleted
                                      ? AppTheme.textPrimary
                                      : AppTheme.textTertiary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],

                // Order Items
                Text(
                  'Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: order.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast =
                          index == order.items.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(
                                AppTheme.spacingBase),
                            child: Row(
                              children: [
                                // 60px square image
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppTheme.radiusMd),
                                  child: CachedImage(
                                    imageUrl: item.image,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppTheme.spacingMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: theme
                                            .textTheme.titleMedium
                                            ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                              AppTheme.spacingXs),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme
                                                          .radiusSm),
                                            ),
                                            child: Text(
                                              'Qty: ${item.quantity}',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color:
                                                    AppTheme.textSecondary,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                    width: AppTheme.spacingSm),
                                Text(
                                  item.total.toPrice,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: AppTheme.border,
                              indent: AppTheme.spacingBase,
                              endIndent: AppTheme.spacingBase,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Payment Summary
                Text(
                  'Payment Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingBase),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                          label: 'Subtotal',
                          value: order.subtotal.toPrice),
                      const SizedBox(height: AppTheme.spacingMd),
                      _SummaryRow(
                        label: 'Delivery Fee',
                        value: order.deliveryFee == 0
                            ? 'FREE'
                            : order.deliveryFee.toPrice,
                        valueColor: order.deliveryFee == 0
                            ? AppTheme.secondary
                            : null,
                      ),
                      if (order.tax > 0) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        _SummaryRow(
                            label: 'Tax',
                            value: order.tax.toPrice),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMd),
                        child: Divider(
                            height: 1, color: AppTheme.border),
                      ),
                      _SummaryRow(
                        label: 'Total',
                        value: order.total.toPrice,
                        isBold: true,
                      ),
                      if (order.paymentMethod != null) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method',
                              style:
                                  theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm),
                              ),
                              child: Text(
                                order.paymentMethod!,
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Delivery Address
                if (order.deliveryAddress != null) ...[
                  Text(
                    'Delivery Address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding:
                        const EdgeInsets.all(AppTheme.spacingBase),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Text(
                            order.deliveryAddress!.fullAddress,
                            style:
                                theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],

                // Cancel button
                if (order.isCancellable)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Material(
                      color: AppTheme.error.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      child: InkWell(
                        onTap: () =>
                            _showCancelDialog(context, ref),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: AppTheme.error,
                              ),
                              const SizedBox(
                                  width: AppTheme.spacingSm),
                              Text(
                                'Cancel Order',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ref.read(orderProvider.notifier).cancelOrder(orderId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Order cancelled successfully'
                        : 'Failed to cancel order'),
                  ),
                );
                if (success) {
                  ref.invalidate(orderDetailProvider(orderId));
                }
              }
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(String step) {
    switch (step) {
      case 'pending':
        return 'Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'out_for_delivery':
        return 'Out for\nDelivery';
      case 'delivered':
        return 'Delivered';
      default:
        return step;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  Color get _color {
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
      default:
        return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
        ),
        Text(
          value,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
        ),
      ],
    );
  }
}
