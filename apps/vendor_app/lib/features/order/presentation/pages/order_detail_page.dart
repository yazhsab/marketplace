import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Order Details',
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
      ),
      body: orderState.when(
        data: (order) {
          if (order == null) {
            return const AppErrorWidget(message: 'Order not found');
          }
          return _buildContent(context, ref, order);
        },
        loading: () => const LoadingWidget(message: 'Loading order...'),
        error: (error, _) => AppErrorWidget(message: error.toString()),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, VendorOrderModel order) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // Order Header Card
        _buildCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${order.orderNumber}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    order.createdAt.toFormattedDateTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Status Timeline
        _buildStatusTimeline(context, order),
        const SizedBox(height: AppTheme.spacingMd),

        // Customer Info Card
        _buildCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Text('Customer Info',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),
              _buildInfoRow(context, Icons.person_outline_rounded,
                  order.customerName),
              if (order.customerPhone != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                _buildInfoRow(context, Icons.phone_outlined,
                    order.customerPhone!),
              ],
              if (order.customerAddress != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                _buildInfoRow(context, Icons.location_on_outlined,
                    order.customerAddress!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Order Items Card
        _buildCard(
          context,
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Text(
                    'Items (${order.items.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),
              ...order.items
                  .map((item) => _buildItemRow(context, item)),
              const Divider(color: AppTheme.border, height: AppTheme.spacingLg),
              _buildPriceRow(context, 'Subtotal', order.subtotal),
              const SizedBox(height: AppTheme.spacingXs),
              _buildPriceRow(context, 'Delivery Fee', order.deliveryFee),
              const Divider(color: AppTheme.border, height: AppTheme.spacingLg),
              _buildPriceRow(context, 'Total', order.totalAmount,
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Payment Info Card
        _buildCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.payment_outlined,
                        color: AppTheme.successColor, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Text('Payment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Method',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      )),
                  Text(order.paymentMethod ?? 'N/A',
                      style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      )),
                  Text(order.paymentStatus ?? 'N/A',
                      style: theme.textTheme.labelLarge),
                ],
              ),
            ],
          ),
        ),

        if (order.notes != null && order.notes!.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingMd),
          _buildCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(Icons.note_alt_outlined,
                          color: AppTheme.warningColor, size: 20),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Text('Notes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(order.notes!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingXl),

        // Action Buttons
        _buildActionButtons(context, ref, order),
        const SizedBox(height: AppTheme.spacingBase),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: child,
    );
  }

  Widget _buildStatusTimeline(BuildContext context, VendorOrderModel order) {
    final theme = Theme.of(context);
    final steps = [
      _TimelineStep('Placed', Icons.receipt_outlined, true),
      _TimelineStep(
          'Confirmed',
          Icons.check_circle_outline,
          ['confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'completed']
              .contains(order.status)),
      _TimelineStep(
          'Preparing',
          Icons.restaurant_outlined,
          ['preparing', 'ready', 'out_for_delivery', 'delivered', 'completed']
              .contains(order.status)),
      _TimelineStep(
          'Ready',
          Icons.inventory_2_outlined,
          ['ready', 'out_for_delivery', 'delivered', 'completed']
              .contains(order.status)),
      _TimelineStep(
          'Delivered',
          Icons.done_all_rounded,
          ['delivered', 'completed'].contains(order.status)),
    ];

    if (order.status == 'cancelled') {
      return _buildCard(
        context,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text('Order Cancelled',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      );
    }

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: AppTheme.spacingBase),
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: step.isCompleted
                                  ? AppTheme.primary
                                  : AppTheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: step.isCompleted
                                    ? AppTheme.primary
                                    : AppTheme.border,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              step.icon,
                              size: 16,
                              color: step.isCompleted
                                  ? Colors.white
                                  : AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            step.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: step.isCompleted
                                  ? AppTheme.primary
                                  : AppTheme.textTertiary,
                              fontWeight: step.isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(
                              bottom: AppTheme.spacingLg),
                          color: step.isCompleted
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, OrderItemModel item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: CachedImage(
              imageUrl: item.image,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity} x ${item.price.toPrice}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(item.total.toPrice, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double amount,
      {bool isBold = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
        ),
        Text(
          amount.toPrice,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                )
              : theme.textTheme.labelLarge,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, VendorOrderModel order) {
    final List<Widget> buttons = [];

    if (order.canConfirm) {
      buttons.addAll([
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _updateStatus(context, ref, order.id, 'cancelled'),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildGradientButton(
            icon: Icons.check_rounded,
            label: 'Confirm',
            onTap: () =>
                _updateStatus(context, ref, order.id, 'confirmed'),
          ),
        ),
      ]);
    } else if (order.canPrepare) {
      buttons.add(
        Expanded(
          child: _buildGradientButton(
            icon: Icons.restaurant_rounded,
            label: 'Start Preparing',
            onTap: () =>
                _updateStatus(context, ref, order.id, 'preparing'),
          ),
        ),
      );
    } else if (order.canMarkReady) {
      buttons.add(
        Expanded(
          child: _buildGradientButton(
            icon: Icons.check_circle_rounded,
            label: 'Mark Ready',
            onTap: () =>
                _updateStatus(context, ref, order.id, 'ready'),
          ),
        ),
      );
    } else if (order.canMarkOutForDelivery) {
      buttons.add(
        Expanded(
          child: _buildGradientButton(
            icon: Icons.delivery_dining_rounded,
            label: 'Out for Delivery',
            onTap: () =>
                _updateStatus(context, ref, order.id, 'out_for_delivery'),
          ),
        ),
      );
    } else if (order.canDeliver) {
      buttons.add(
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.successColor, Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    _updateStatus(context, ref, order.id, 'delivered'),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.done_all_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Mark Delivered',
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    label,
                    style:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String id, String status) async {
    try {
      await ref
          .read(orderProvider.notifier)
          .updateOrderStatus(id, status);
      ref.invalidate(orderDetailProvider(id));
      if (context.mounted) {
        context.showSuccessSnackBar('Order status updated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(e.toString(), isError: true);
      }
    }
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool isCompleted;

  _TimelineStep(this.label, this.icon, this.isCompleted);
}
