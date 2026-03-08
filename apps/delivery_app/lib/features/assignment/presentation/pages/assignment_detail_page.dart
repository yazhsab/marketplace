import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/assignment_model.dart';
import '../providers/assignment_provider.dart';

final assignmentDetailProvider = FutureProvider.family<AssignmentModel?, String>(
    (ref, id) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.deliveryAssignmentById(id));
  return AssignmentModel.fromJson(
      response.data['data'] as Map<String, dynamic>);
});

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  final _otpController = TextEditingController();
  bool _isActioning = false;
  bool _isDetailsExpanded = true;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppTheme.secondary;
      case 'accepted':
        return AppTheme.accent;
      case 'picked_up':
        return AppTheme.primary;
      case 'delivered':
        return AppTheme.successColor;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(assignmentDetailProvider(widget.assignmentId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Assignment Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => const LoadingWidget(message: 'Loading assignment...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(
              assignmentDetailProvider(widget.assignmentId)),
        ),
        data: (assignment) {
          if (assignment == null) {
            return const AppErrorWidget(message: 'Assignment not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- Large Status Badge + Order# --
                _buildStatusHeader(theme, assignment),
                const SizedBox(height: AppTheme.spacingLg),

                // -- Route Visualization --
                _buildRouteVisualization(theme, assignment),
                const SizedBox(height: AppTheme.spacingLg),

                // -- Order Details Expandable Card --
                _buildDetailsCard(theme, assignment),
                const SizedBox(height: AppTheme.spacingLg),

                // -- OTP Section for delivery confirmation --
                if (assignment.isPickedUp)
                  _buildOtpSection(theme, assignment),

                // -- Action Buttons --
                _buildActionButtons(context, assignment),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme, AssignmentModel assignment) {
    final statusColor = _statusColor(assignment.status);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.orderNumber ?? 'Assignment',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  assignment.createdAt.toFormattedDateTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  assignment.status.replaceAll('_', ' ').capitalize,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteVisualization(
      ThemeData theme, AssignmentModel assignment) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // Pickup Point
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  // Green dot for pickup
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                  // Dotted connector
                  ...List.generate(
                    4,
                    (_) => Container(
                      width: 2,
                      height: 8,
                      margin:
                          const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.05),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color:
                          AppTheme.successColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PICKUP FROM',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        assignment.vendorName ?? 'Vendor',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (assignment.vendorAddress != null) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          assignment.vendorAddress!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXs),

          // Delivery Point
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red pin for delivery
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.05),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVER TO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        assignment.customerName ?? 'Customer',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (assignment.customerAddress != null) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          assignment.customerAddress!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Distance info
          if (assignment.distanceKm != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 16, color: AppTheme.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    assignment.distanceKm!.toKm,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme, AssignmentModel assignment) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () =>
                setState(() => _isDetailsExpanded = !_isDetailsExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 18, color: AppTheme.primary),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      'Order Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isDetailsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingBase,
                0,
                AppTheme.spacingBase,
                AppTheme.spacingBase,
              ),
              child: Column(
                children: [
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: AppTheme.spacingSm),
                  if (assignment.orderTotal != null)
                    _buildDetailRow(theme, 'Order Total',
                        assignment.orderTotal!.toPrice),
                  if (assignment.distanceKm != null)
                    _buildDetailRow(
                        theme, 'Distance', assignment.distanceKm!.toKm),
                  if (assignment.earnings != null)
                    _buildDetailRow(theme, 'Your Earnings',
                        assignment.earnings!.toPrice,
                        valueColor: AppTheme.successColor),
                  if (assignment.deliveryOtp != null &&
                      assignment.isAccepted)
                    _buildDetailRow(
                        theme, 'Delivery OTP', assignment.deliveryOtp!,
                        highlight: true),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isDetailsExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value,
      {bool highlight = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Container(
            padding: highlight
                ? const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingXs,
                  )
                : null,
            decoration: highlight
                ? BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.3),
                    ),
                  )
                : null,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight
                    ? AppTheme.secondary
                    : valueColor ?? AppTheme.textPrimary,
                fontSize: highlight ? 16 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection(ThemeData theme, AssignmentModel assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.pin_outlined,
                    size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Delivery Confirmation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            'Enter the 6-digit OTP from customer to confirm delivery',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: theme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.textTertiary,
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AssignmentModel assignment) {
    final theme = Theme.of(context);

    if (assignment.isDelivered ||
        assignment.isRejected ||
        assignment.isCancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (assignment.isAssigned) ...[
          // Accept Button
          Container(
            decoration: BoxDecoration(
              gradient:
                  _isActioning ? null : AppTheme.primaryGradient,
              color: _isActioning
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: _isActioning
                  ? null
                  : [
                      BoxShadow(
                        color:
                            AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed:
                  _isActioning ? null : () => _handleAccept(assignment),
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Accept Assignment',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Reject Button
          OutlinedButton.icon(
            onPressed:
                _isActioning ? null : () => _handleReject(assignment),
            icon: const Icon(Icons.close, color: AppTheme.error),
            label: Text(
              'Reject',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.error,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
          ),
        ],
        if (assignment.isAccepted)
          Container(
            decoration: BoxDecoration(
              gradient:
                  _isActioning ? null : AppTheme.primaryGradient,
              color: _isActioning
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: _isActioning
                  ? null
                  : [
                      BoxShadow(
                        color:
                            AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed:
                  _isActioning ? null : () => _handlePickup(assignment),
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              label: Text(
                'Mark as Picked Up',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        if (assignment.isPickedUp) ...[
          Container(
            decoration: BoxDecoration(
              gradient: _isActioning
                  ? null
                  : const LinearGradient(
                      colors: [
                        AppTheme.successColor,
                        Color(0xFF34D399),
                      ],
                    ),
              color: _isActioning
                  ? AppTheme.successColor.withValues(alpha: 0.5)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: _isActioning
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.successColor
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed:
                  _isActioning ? null : () => _handleDeliver(assignment),
              icon:
                  const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                'Confirm Delivery',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  Future<void> _handleAccept(AssignmentModel assignment) async {
    setState(() => _isActioning = true);
    final success = await ref
        .read(assignmentListProvider.notifier)
        .acceptAssignment(assignment.id);
    setState(() => _isActioning = false);
    if (success && mounted) {
      context.showSuccessSnackBar('Assignment accepted');
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    }
  }

  Future<void> _handleReject(AssignmentModel assignment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
            'Reject Assignment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (reason == null) return;

    setState(() => _isActioning = true);
    final success = await ref
        .read(assignmentListProvider.notifier)
        .rejectAssignment(assignment.id,
            reason: reason.isNotEmpty ? reason : null);
    setState(() => _isActioning = false);
    if (success && mounted) {
      context.showSnackBar('Assignment rejected');
      Navigator.pop(context);
    }
  }

  Future<void> _handlePickup(AssignmentModel assignment) async {
    setState(() => _isActioning = true);
    final success = await ref
        .read(assignmentListProvider.notifier)
        .pickupOrder(assignment.id);
    setState(() => _isActioning = false);
    if (success && mounted) {
      context.showSuccessSnackBar('Order picked up');
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    }
  }

  Future<void> _handleDeliver(AssignmentModel assignment) async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      context.showSnackBar('Please enter the 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isActioning = true);
    final success = await ref
        .read(assignmentListProvider.notifier)
        .deliverOrder(assignment.id, otp: otp);
    setState(() => _isActioning = false);
    if (success && mounted) {
      context.showSuccessSnackBar('Order delivered successfully!');
      Navigator.pop(context);
    }
  }
}
