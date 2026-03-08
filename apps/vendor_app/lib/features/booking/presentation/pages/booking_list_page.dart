import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';

class BookingListPage extends ConsumerStatefulWidget {
  const BookingListPage({super.key});

  @override
  ConsumerState<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends ConsumerState<BookingListPage> {
  int _selectedFilter = 0;

  final _filterLabels = const ['All', 'Today', 'Upcoming', 'Past'];

  List<VendorBookingModel> _filterBookings(
      List<VendorBookingModel> bookings) {
    switch (_selectedFilter) {
      case 1:
        return bookings.where((b) => b.scheduledDate.isToday).toList();
      case 2:
        return bookings
            .where((b) => b.isUpcoming && !b.scheduledDate.isToday)
            .toList();
      case 3:
        return bookings
            .where((b) => !b.isUpcoming && !b.scheduledDate.isToday)
            .toList();
      default:
        return bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Bookings', style: theme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(bookingProvider.notifier).loadBookings(),
          ),
        ],
      ),
      body: bookingState.isLoading
          ? const LoadingWidget(message: 'Loading bookings...')
          : bookingState.error != null
              ? AppErrorWidget(
                  message: bookingState.error!,
                  onRetry: () =>
                      ref.read(bookingProvider.notifier).loadBookings(),
                )
              : bookingState.bookings.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(bookingProvider.notifier).loadBookings(),
                      child: Column(
                        children: [
                          // Filter chips
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingBase,
                              vertical: AppTheme.spacingSm,
                            ),
                            child: SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filterLabels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppTheme.spacingSm),
                                itemBuilder: (context, index) {
                                  final isSelected =
                                      _selectedFilter == index;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedFilter = index),
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
                                      ),
                                      child: Text(
                                        _filterLabels[index],
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Booking list
                          Expanded(
                            child: _buildBookingList(
                              context,
                              ref,
                              _filterBookings(bookingState.bookings),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              'No bookings yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Bookings from customers will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, WidgetRef ref,
      List<VendorBookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No bookings in this category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    // Group bookings by section
    final todayBookings =
        bookings.where((b) => b.scheduledDate.isToday).toList();
    final upcomingBookings = bookings
        .where((b) => b.isUpcoming && !b.scheduledDate.isToday)
        .toList();
    final pastBookings = bookings
        .where((b) => !b.isUpcoming && !b.scheduledDate.isToday)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        if (todayBookings.isNotEmpty) ...[
          _buildGroupHeader(context, "Today's Bookings",
              '${todayBookings.length}'),
          const SizedBox(height: AppTheme.spacingSm),
          ...todayBookings
              .map((b) => _buildBookingCard(context, ref, b)),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        if (upcomingBookings.isNotEmpty) ...[
          _buildGroupHeader(
              context, 'Upcoming', '${upcomingBookings.length}'),
          const SizedBox(height: AppTheme.spacingSm),
          ...upcomingBookings
              .map((b) => _buildBookingCard(context, ref, b)),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        if (pastBookings.isNotEmpty) ...[
          _buildGroupHeader(context, 'Past', '${pastBookings.length}'),
          const SizedBox(height: AppTheme.spacingSm),
          ...pastBookings
              .map((b) => _buildBookingCard(context, ref, b)),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(
      BuildContext context, String title, String count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            count,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, WidgetRef ref,
      VendorBookingModel booking) {
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
          onTap: () => context.push('/bookings/${booking.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    StatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Customer row with avatar
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          booking.customerName.isNotEmpty
                              ? booking.customerName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        booking.customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Date + time + duration row
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        booking.scheduledDate.toFormattedDate,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingBase),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        booking.scheduledTime,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          '${booking.durationMinutes} min',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      booking.servicePrice.toPrice,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),

                // Action buttons for confirmable bookings
                if (booking.canConfirm) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ref
                              .read(bookingProvider.notifier)
                              .updateBookingStatus(
                                  booking.id, 'cancelled'),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(
                                color: AppTheme.error, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd),
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ref
                              .read(bookingProvider.notifier)
                              .updateBookingStatus(
                                  booking.id, 'confirmed'),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd),
                            ),
                            minimumSize: const Size(0, 44),
                          ),
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
