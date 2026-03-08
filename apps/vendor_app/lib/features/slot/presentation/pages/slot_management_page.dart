import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/slot_model.dart';
import '../providers/slot_provider.dart';

class SlotManagementPage extends ConsumerStatefulWidget {
  const SlotManagementPage({super.key});

  @override
  ConsumerState<SlotManagementPage> createState() =>
      _SlotManagementPageState();
}

class _SlotManagementPageState extends ConsumerState<SlotManagementPage> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final slotsState = ref.watch(slotProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Manage Slots',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 12,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateSlotDialog(context, selectedDate),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Calendar strip
          _buildCalendarStrip(context, selectedDate, theme),
          const Divider(height: 1, color: AppTheme.border),
          // Slot list
          Expanded(
            child: _buildSlotList(slotsState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotList(SlotState slotsState, ThemeData theme) {
    if (slotsState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        itemCount: 4,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: SkeletonListTile(),
        ),
      );
    }

    if (slotsState.error != null && slotsState.slots.isEmpty) {
      return AppErrorWidget(
        message: slotsState.error!,
        onRetry: () => ref.read(slotProvider.notifier).loadSlots(),
      );
    }

    if (slotsState.slots.isEmpty) {
      return const EmptyStateWidget(
        message: 'No slots for this date.\nTap + to create one.',
        icon: Icons.event_busy,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      itemCount: slotsState.slots.length,
      itemBuilder: (context, index) =>
          _buildSlotCard(context, slotsState.slots[index], theme),
    );
  }

  Widget _buildCalendarStrip(
      BuildContext context, DateTime selectedDate, ThemeData theme) {
    final today = DateTime.now();
    final dates = List.generate(
      14,
      (i) => DateTime(today.year, today.month, today.day + i),
    );

    return Container(
      height: 90,
      color: AppTheme.card,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingSm,
        ),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = date;
              ref.read(slotProvider.notifier).loadSlots();
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.border),
                boxShadow: isSelected ? AppTheme.shadowSm : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date.isToday ? 'Today' : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotCard(
      BuildContext context, SlotModel slot, ThemeData theme) {
    final isFull = slot.isFull;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isFull
                    ? AppTheme.error.withValues(alpha: 0.1)
                    : AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                isFull ? Icons.event_busy : Icons.event_available,
                color: isFull ? AppTheme.error : AppTheme.successColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            // Time and booking info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.startTime} - ${slot.endTime}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isFull
                              ? AppTheme.error.withValues(alpha: 0.1)
                              : AppTheme.successColor
                                  .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          '${slot.currentBookings}/${slot.maxBookings} bookings${isFull ? ' (Full)' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isFull
                                ? AppTheme.error
                                : AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.error.withValues(alpha: 0.7),
              ),
              onPressed: () => _confirmDeleteSlot(context, slot),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSlot(BuildContext context, SlotModel slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
            'Delete slot ${slot.startTime} - ${slot.endTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(slotProvider.notifier).deleteSlot(slot.id);
                if (mounted) {
                  context.showSuccessSnackBar('Slot deleted');
                }
              } catch (e) {
                if (mounted) {
                  context.showSnackBar(e.toString(), isError: true);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateSlotDialog(BuildContext context, DateTime selectedDate) {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    final maxBookingsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Create Slot - ${selectedDate.toFormattedDate}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Time'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                    child: Text(startTime.formatted),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Time'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setDialogState(() => endTime = picked);
                      }
                    },
                    child: Text(endTime.formatted),
                  ),
                ),
                TextField(
                  controller: maxBookingsController,
                  decoration: const InputDecoration(
                    labelText: 'Max Bookings',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref.read(slotProvider.notifier).createSlot({
                      'date': selectedDate.toApiDate,
                      'startTime': startTime.formatted,
                      'endTime': endTime.formatted,
                      'maxBookings':
                          int.tryParse(maxBookingsController.text) ?? 1,
                    });
                    if (mounted) {
                      context.showSuccessSnackBar('Slot created');
                    }
                  } catch (e) {
                    if (mounted) {
                      context.showSnackBar(e.toString(), isError: true);
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
