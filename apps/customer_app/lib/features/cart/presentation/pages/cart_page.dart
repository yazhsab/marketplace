import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../providers/cart_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final total = ref.watch(cartTotalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Shopping Cart', style: theme.textTheme.titleLarge),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                        'Are you sure you want to remove all items?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Clear All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState(context, ref)
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingBase),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingMd),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: ValueKey(item.productId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          ref
                              .read(cartProvider.notifier)
                              .removeItem(item.productId);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(
                              right: AppTheme.spacingXl),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                'Delete',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Product Image - 80px square
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd),
                                child: CachedImage(
                                  imageUrl: item.image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
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
                                        ),
                                        const SizedBox(
                                            width: AppTheme.spacingSm),
                                        InkWell(
                                          onTap: () {
                                            ref
                                                .read(cartProvider
                                                    .notifier)
                                                .removeItem(
                                                    item.productId);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppTheme.radiusFull),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppTheme.surface,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color:
                                                  AppTheme.textTertiary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: AppTheme.spacingXs),
                                    Text(
                                      item.price.toPrice,
                                      style: theme
                                          .textTheme.titleMedium
                                          ?.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: AppTheme.spacingSm),

                                    // Quantity stepper + line total
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppTheme.border),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppTheme.radiusSm),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              _QuantityButton(
                                                icon: Icons.remove,
                                                onPressed: () {
                                                  ref
                                                      .read(cartProvider
                                                          .notifier)
                                                      .decrementQuantity(
                                                          item
                                                              .productId);
                                                },
                                              ),
                                              Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 36),
                                                alignment:
                                                    Alignment.center,
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: AppTheme
                                                        .spacingSm),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: theme.textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              _QuantityButton(
                                                icon: Icons.add,
                                                onPressed: () {
                                                  ref
                                                      .read(cartProvider
                                                          .notifier)
                                                      .incrementQuantity(
                                                          item
                                                              .productId);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          (item.price * item.quantity)
                                              .toPrice,
                                          style: theme
                                              .textTheme.labelLarge
                                              ?.copyWith(
                                            color:
                                                AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
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
                      );
                    },
                  ),
                ),

                // Summary card + sticky bottom bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    boxShadow: AppTheme.shadowLg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppTheme.spacingBase),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(
                                  bottom: AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: AppTheme.border,
                                borderRadius:
                                    BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Summary card
                          Container(
                            padding: const EdgeInsets.all(
                                AppTheme.spacingBase),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd),
                              border:
                                  Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              children: [
                                _PriceRow(
                                    label: 'Subtotal',
                                    value: subtotal),
                                const SizedBox(
                                    height: AppTheme.spacingSm),
                                _PriceRow(
                                  label: 'Delivery Fee',
                                  value: deliveryFee,
                                  valueColor: deliveryFee == 0
                                      ? AppTheme.secondary
                                      : null,
                                  valueLabel: deliveryFee == 0
                                      ? 'FREE'
                                      : null,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical:
                                              AppTheme.spacingSm),
                                  child: Divider(
                                      color: AppTheme.border,
                                      height: 1),
                                ),
                                _PriceRow(
                                  label: 'Total',
                                  value: total,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingBase),

                          // Checkout button row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: AppTheme.spacingXs),
                                    Text(
                                      total.toPrice,
                                      style: theme
                                          .textTheme.titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient:
                                        AppTheme.primaryGradient,
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppTheme.radiusLg),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          context.push('/checkout'),
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.radiusLg),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Checkout',
                                            style: theme
                                                .textTheme.labelLarge
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(
                                              width:
                                                  AppTheme.spacingSm),
                                          const Icon(
                                            Icons
                                                .arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppTheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Start shopping to add items!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
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
                  onTap: () => context.go('/'),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing2xl,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          'Browse Products',
                          style:
                              theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? valueColor;
  final String? valueLabel;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
    this.valueLabel,
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
          valueLabel ?? value.toPrice,
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
