import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String _selectedPaymentMethod = 'cod';
  bool _isPlacingOrder = false;

  final _addressFormKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_addressFormKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);

    final cartItems = ref.read(cartProvider);
    final items = cartItems
        .map((item) => {
              'productId': item.productId,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'image': item.image,
            })
        .toList();

    final address = OrderAddress(
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    final success = await ref.read(orderProvider.notifier).createOrder(
          items: items,
          deliveryAddress: address.toJson(),
          paymentMethod: _selectedPaymentMethod,
        );

    setState(() => _isPlacingOrder = false);

    if (mounted) {
      if (success) {
        ref.read(cartProvider.notifier).clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        context.go('/orders');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to place order. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final total = ref.watch(cartTotalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: theme.textTheme.titleLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Delivery Address Section ──
                  _SectionHeader(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Address',
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Form(
                    key: _addressFormKey,
                    child: Container(
                      padding:
                          const EdgeInsets.all(AppTheme.spacingBase),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _addressLine1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Address Line 1',
                              hintText: 'House/Flat No., Street',
                              prefixIcon:
                                  Icon(Icons.home_outlined, size: 20),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          TextFormField(
                            controller: _addressLine2Controller,
                            decoration: const InputDecoration(
                              labelText: 'Address Line 2 (Optional)',
                              hintText: 'Landmark, Area',
                              prefixIcon: Icon(
                                  Icons.location_city_outlined,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(
                                  width: AppTheme.spacingMd),
                              Expanded(
                                child: TextFormField(
                                  controller: _stateController,
                                  decoration: const InputDecoration(
                                    labelText: 'State',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pincodeController,
                                  keyboardType:
                                      TextInputType.number,
                                  maxLength: 6,
                                  decoration: const InputDecoration(
                                    labelText: 'Pincode',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.length != 6) {
                                      return 'Invalid pincode';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(
                                  width: AppTheme.spacingMd),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType:
                                      TextInputType.phone,
                                  maxLength: 10,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // ── Payment Method Section ──
                  _SectionHeader(
                    icon: Icons.payment_outlined,
                    title: 'Payment Method',
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _PaymentOption(
                          icon: Icons.money_rounded,
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when you receive',
                          value: 'cod',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() =>
                                _selectedPaymentMethod = value!);
                          },
                        ),
                        Divider(
                          height: 1,
                          color: AppTheme.border,
                          indent: AppTheme.spacingBase,
                          endIndent: AppTheme.spacingBase,
                        ),
                        _PaymentOption(
                          icon: Icons.account_balance_outlined,
                          title: 'Online Payment',
                          subtitle: 'Pay via UPI, Card, Net Banking',
                          value: 'online',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() =>
                                _selectedPaymentMethod = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // ── Order Summary Section ──
                  _SectionHeader(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order Summary',
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        ...cartItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isLast =
                              index == cartItems.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingBase,
                                  vertical: AppTheme.spacingMd,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: theme
                                            .textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppTheme
                                              .textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            AppTheme.spacingSm),
                                    Text(
                                      'x${item.quantity}',
                                      style: theme
                                          .textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme
                                            .textTertiary,
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            AppTheme.spacingBase),
                                    Text(
                                      item.total.toPrice,
                                      style: theme
                                          .textTheme.labelLarge
                                          ?.copyWith(
                                        color: AppTheme
                                            .textPrimary,
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
                                  endIndent:
                                      AppTheme.spacingBase,
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),

                  // ── Price Summary Card ──
                  Container(
                    padding:
                        const EdgeInsets.all(AppTheme.spacingBase),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _PriceRow(
                            label: 'Subtotal',
                            value: subtotal.toPrice),
                        const SizedBox(height: AppTheme.spacingSm),
                        _PriceRow(
                          label: 'Delivery Fee',
                          value: deliveryFee == 0
                              ? 'FREE'
                              : deliveryFee.toPrice,
                          valueColor: deliveryFee == 0
                              ? AppTheme.secondary
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd),
                          child: Divider(
                              height: 1, color: AppTheme.border),
                        ),
                        _PriceRow(
                          label: 'Total',
                          value: total.toPrice,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom: Place Order Button ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              boxShadow: AppTheme.shadowLg,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isPlacingOrder
                          ? null
                          : AppTheme.primaryGradient,
                      color: _isPlacingOrder
                          ? AppTheme.textTertiary
                          : null,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: _isPlacingOrder
                          ? null
                          : [
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
                        onTap:
                            _isPlacingOrder ? null : _placeOrder,
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          child: Center(
                            child: _isPlacingOrder
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Place Order  -  ${total.toPrice}',
                                    style: theme
                                        .textTheme.labelLarge
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingBase,
          vertical: AppTheme.spacingMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : AppTheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _PriceRow({
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
