import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../service/presentation/providers/service_provider.dart';
import '../providers/booking_provider.dart';

class BookingCreatePage extends ConsumerStatefulWidget {
  final String serviceId;

  const BookingCreatePage({super.key, required this.serviceId});

  @override
  ConsumerState<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends ConsumerState<BookingCreatePage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  String _paymentMethod = 'online';
  final _notesController = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  Future<void> _bookService(double price) async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isBooking = true);

    final success = await ref.read(bookingProvider.notifier).createBooking(
          serviceId: widget.serviceId,
          scheduledDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          startTime: _selectedSlot!.startTime,
          endTime: _selectedSlot!.endTime,
          paymentMethod: _paymentMethod,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

    setState(() => _isBooking = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed!')),
        );
        context.go('/bookings');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slotsAsync = ref.watch(
      serviceSlotsProvider(
        ServiceSlotQuery(serviceId: widget.serviceId, date: dateString),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
      ),
      body: serviceAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => AppErrorWidget(message: error.toString()),
        data: (service) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service info
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.handyman,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${service.formattedDuration} | ${service.price.toPrice}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Date picker
                Text(
                  'Select Date',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate.toFormattedDate,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Time slots
                Text(
                  'Available Time Slots',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                slotsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'No slots available for this date',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  data: (slots) {
                    if (slots.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No slots available for this date',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((slot) {
                        final isSelected = _selectedSlot?.id == slot.id;
                        return ChoiceChip(
                          label: Text(
                            '${slot.startTime} - ${slot.endTime}',
                          ),
                          selected: isSelected,
                          onSelected: slot.isAvailable
                              ? (selected) {
                                  setState(() {
                                    _selectedSlot = selected ? slot : null;
                                  });
                                }
                              : null,
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          disabledColor: Colors.grey.shade200,
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Any special instructions...',
                  ),
                ),
                const SizedBox(height: 24),

                // Payment method
                Text(
                  'Payment Method',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Pay Online'),
                        value: 'online',
                        groupValue: _paymentMethod,
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v!),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Pay After Service'),
                        value: 'cod',
                        groupValue: _paymentMethod,
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Price summary
                Card(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          service.price.toPrice,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Book button
                ElevatedButton(
                  onPressed: _isBooking
                      ? null
                      : () => _bookService(service.price),
                  child: _isBooking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Book & Pay - ${service.price.toPrice}'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
