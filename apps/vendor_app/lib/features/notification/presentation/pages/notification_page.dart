import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String?,
      referenceId: json['referenceId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationState {
  final bool isLoading;
  final String? error;
  final List<NotificationModel> notifications;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    List<NotificationModel>? notifications,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notifications: notifications ?? this.notifications,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.notifications);

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isLoading: false,
        notifications: items
            .map((e) =>
                NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient
          .patch(ApiEndpoints.markNotificationRead(id), data: {});
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient
          .patch(ApiEndpoints.markAllNotificationsRead, data: {});
      await loadNotifications();
    } catch (_) {}
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifState.notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: () => ref
                  .read(notificationProvider.notifier)
                  .markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
              ),
            ),
        ],
      ),
      body: notifState.isLoading
          ? const LoadingWidget(message: 'Loading notifications...')
          : notifState.error != null
              ? AppErrorWidget(
                  message: notifState.error!,
                  onRetry: () => ref
                      .read(notificationProvider.notifier)
                      .loadNotifications(),
                )
              : notifState.notifications.isEmpty
                  ? const EmptyStateWidget(
                      message: 'No notifications',
                      icon: Icons.notifications_none,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(notificationProvider.notifier)
                          .loadNotifications(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        itemCount: notifState.notifications.length,
                        itemBuilder: (context, index) =>
                            _buildNotificationTile(
                          context,
                          ref,
                          notifState.notifications[index],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, WidgetRef ref, NotificationModel notif) {
    final theme = Theme.of(context);
    final iconColor = _getIconColor(notif.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: notif.isRead
            ? AppTheme.card
            : AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: notif.isRead
              ? AppTheme.border
              : AppTheme.primary.withValues(alpha: 0.15),
        ),
        boxShadow: notif.isRead ? [] : AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {
            if (!notif.isRead) {
              ref
                  .read(notificationProvider.notifier)
                  .markAsRead(notif.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(notif.type),
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        notif.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: AppTheme.textTertiary),
                          const SizedBox(width: AppTheme.spacingXs),
                          Text(
                            notif.createdAt.toTimeAgo,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.textTertiary,
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
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'payout':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'order':
        return AppTheme.primary;
      case 'booking':
        return AppTheme.secondary;
      case 'review':
        return AppTheme.warningColor;
      case 'payout':
        return AppTheme.successColor;
      default:
        return const Color(0xFF6366F1);
    }
  }
}
