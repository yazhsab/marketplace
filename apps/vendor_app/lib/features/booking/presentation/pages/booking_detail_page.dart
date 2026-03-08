import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: bookingState.when(
        data: (booking) {
          if (booking == null) {
            return const AppErrorWidget(message: 'Booking not found');
          }
          return _buildContent(context, ref, booking);
        },
        loading: () => _buildSkeletonLoading(),
        error: (error, _) =>
            AppErrorWidget(message: error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      VendorBookingModel booking) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              // Status Header Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(AppTheme.spacingSm),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Text(
                              '#${booking.bookingNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          booking.createdAt.toFormattedDateTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingBase),

              // Service Info Card
              _buildSectionCard(
                context,
                icon: Icons.design_services_rounded,
                iconColor: AppTheme.secondary,
                title: 'Service',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
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
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          booking.servicePrice.toPrice,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    text: booking.scheduledDate.toFormattedDate,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _buildInfoRow(
                    context,
                    icon: Icons.access_time_rounded,
                    text:
                        '${booking.scheduledTime} (${booking.durationMinutes} min)',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),

              // Customer Info Card
              _buildSectionCard(
                context,
                icon: Icons.person_rounded,
                iconColor: AppTheme.successColor,
                title: 'Customer',
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            booking.customerName.isNotEmpty
                                ? booking.customerName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (booking.customerPhone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                booking.customerPhone!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Notes Card
              if (booking.notes != null &&
                  booking.notes!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingBase),
                _buildSectionCard(
                  context,
                  icon: Icons.note_alt_rounded,
                  iconColor: AppTheme.warningColor,
                  title: 'Notes',
                  children: [
                    Text(
                      booking.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),

        // Bottom Action Buttons
        _buildBottomActionBar(context, ref, booking),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: AppTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context, WidgetRef ref,
      VendorBookingModel booking) {
    final List<Widget> buttons = [];

    if (booking.canConfirm) {
      buttons.addAll([
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _updateStatus(context, ref, booking.id, 'cancelled'),
            icon: const Icon(Icons.close_rounded, size: 20),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              minimumSize: const Size(0, 52),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                _updateStatus(context, ref, booking.id, 'confirmed'),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              minimumSize: const Size(0, 52),
            ),
          ),
        ),
      ]);
    } else if (booking.canStart) {
      buttons.add(
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () =>
                  _updateStatus(context, ref, booking.id, 'in_progress'),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ),
      );
    } else if (booking.canComplete) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                _updateStatus(context, ref, booking.id, 'completed'),
            icon: const Icon(Icons.done_all_rounded, size: 20),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingMd,
        AppTheme.spacingBase,
        MediaQuery.of(context).padding.bottom + AppTheme.spacingBase,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: const Border(
          top: BorderSide(color: AppTheme.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: buttons),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // Status header skeleton
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _shimmerBox(width: 36, height: 36, radius: AppTheme.radiusSm),
                      const SizedBox(width: AppTheme.spacingMd),
                      _shimmerBox(width: 100, height: 18),
                    ],
                  ),
                  _shimmerBox(width: 80, height: 26, radius: AppTheme.radiusFull),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: AppTheme.spacingMd),
              _shimmerBox(width: 180, height: 14),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingBase),
        // Section card skeleton x3
        for (int i = 0; i < 3; i++) ...[
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _shimmerBox(width: 28, height: 28, radius: AppTheme.radiusSm),
                    const SizedBox(width: AppTheme.spacingSm),
                    _shimmerBox(width: 80, height: 16),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: AppTheme.spacingMd),
                _shimmerBox(width: double.infinity, height: 16),
                const SizedBox(height: AppTheme.spacingSm),
                _shimmerBox(width: 200, height: 14),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
        ],
      ],
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

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String id, String status) async {
    try {
      await ref
          .read(bookingProvider.notifier)
          .updateBookingStatus(id, status);
      ref.invalidate(bookingDetailProvider(id));
      if (context.mounted) {
        context.showSuccessSnackBar('Booking status updated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(e.toString(), isError: true);
      }
    }
  }
}
