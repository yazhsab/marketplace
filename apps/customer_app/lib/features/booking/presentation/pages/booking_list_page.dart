import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';

class BookingListPage extends ConsumerStatefulWidget {
  const BookingListPage({super.key});

  @override
  ConsumerState<BookingListPage> createState() =>
      _BookingListPageState();
}

class _BookingListPageState extends ConsumerState<BookingListPage> {
  String _selectedFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'upcoming', 'label': 'Upcoming'},
    {'key': 'completed', 'label': 'Completed'},
    {'key': 'cancelled', 'label': 'Cancelled'},
  ];

  List<BookingModel> _filterBookings(BookingListState state) {
    switch (_selectedFilter) {
      case 'upcoming':
        return state.upcomingBookings;
      case 'completed':
        return state.pastBookings
            .where((b) => b.status == 'completed')
            .toList();
      case 'cancelled':
        return [
          ...state.upcomingBookings,
          ...state.pastBookings,
        ].where((b) => b.status == 'cancelled').toList();
      default:
        return [
          ...state.upcomingBookings,
          ...state.pastBookings,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings', style: theme.textTheme.titleLarge),
      ),
      body: state.isLoading
          ? Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Column(
                children: List.generate(
                  5,
                  (_) => const Padding(
                    padding:
                        EdgeInsets.only(bottom: AppTheme.spacingMd),
                    child: SkeletonListTile(),
                  ),
                ),
              ),
            )
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref
                      .read(bookingProvider.notifier)
                      .loadBookings(),
                )
              : Column(
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
                                  horizontal:
                                      AppTheme.spacingBase,
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
                                  filter['label'] as String,
                                  style: theme
                                      .textTheme.labelLarge
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

                    // Booking list
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filteredBookings =
                              _filterBookings(state);
                          if (filteredBookings.isEmpty) {
                            return EmptyStateWidget(
                              message: _selectedFilter == 'all'
                                  ? 'No bookings yet.\nBook a service to get started!'
                                  : 'No ${_filters.firstWhere((f) => f['key'] == _selectedFilter)['label']?.toString().toLowerCase()} bookings',
                              icon:
                                  Icons.calendar_today_outlined,
                            );
                          }
                          return RefreshIndicator(
                            color: AppTheme.primary,
                            onRefresh: () => ref
                                .read(bookingProvider.notifier)
                                .loadBookings(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    AppTheme.spacingBase,
                              ),
                              itemCount:
                                  filteredBookings.length,
                              itemBuilder: (context, index) {
                                return _BookingCard(
                                  booking:
                                      filteredBookings[index],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'in_progress':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.secondary;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(booking.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: GestureDetector(
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service name + status badge
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull),
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
                          booking.statusDisplay,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Date + Time row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(
                      AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.scheduledDate.toFormattedDate,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm),
                      color: AppTheme.border,
                    ),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.startTime} - ${booking.endTime}',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Vendor + Price
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  if (booking.vendorName != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              booking.vendorName!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    booking.price.toPrice,
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
