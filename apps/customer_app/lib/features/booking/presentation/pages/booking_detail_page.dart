import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/booking_provider.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: bookingAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
        ),
        data: (booking) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking header
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Booking #${booking.bookingNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            _StatusBadge(
                              status: booking.status,
                              label: booking.statusDisplay,
                            ),
                          ],
                        ),
                        if (booking.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Booked on ${booking.createdAt!.toFormattedDateTime}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Service info
                Text(
                  'Service',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.1),
                      child: Icon(
                        Icons.handyman,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: Text(
                      booking.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(booking.price.toPrice),
                  ),
                ),
                const SizedBox(height: 16),

                // Schedule
                Text(
                  'Schedule',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              booking.scheduledDate.toFormattedDate,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              '${booking.startTime} - ${booking.endTime}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vendor contact
                if (booking.vendorName != null) ...[
                  Text(
                    'Service Provider',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        child: Icon(
                          Icons.store,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(booking.vendorName!),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {
                          // Handle call
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  Text(
                    'Notes',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        booking.notes!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment info
                Text(
                  'Payment',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount'),
                            Text(
                              booking.price.toPrice,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (booking.paymentMethod != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Method',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              Text(booking.paymentMethod!),
                            ],
                          ),
                        ],
                        if (booking.paymentStatus != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Status',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              Text(booking.paymentStatus!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cancel button
                if (booking.isCancellable)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
                const SizedBox(height: 24),
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
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(bookingProvider.notifier)
                  .cancelBooking(bookingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Booking cancelled successfully'
                        : 'Failed to cancel booking'),
                  ),
                );
                if (success) {
                  ref.invalidate(bookingDetailProvider(bookingId));
                }
              }
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  Color get _color {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
