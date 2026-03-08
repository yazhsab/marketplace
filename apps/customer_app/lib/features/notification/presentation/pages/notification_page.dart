import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.isRead = false,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  IconData get icon {
    switch (type) {
      case 'order':
        return Icons.receipt_long;
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'promotion':
        return Icons.local_offer;
      case 'review':
        return Icons.star;
      case 'delivery':
        return Icons.local_shipping;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'order':
        return const Color(0xFF0984E3);
      case 'booking':
        return AppTheme.primary;
      case 'payment':
        return AppTheme.secondary;
      case 'promotion':
        return const Color(0xFFE17055);
      case 'review':
        return AppTheme.accent;
      case 'delivery':
        return const Color(0xFF00B894);
      default:
        return AppTheme.textSecondary;
    }
  }
}

// Notification state
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

  int get unreadCount => notifications.where((n) => !n.isRead).length;
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

  Future<void> markAsRead(String notificationId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient
          .post(ApiEndpoints.markNotificationRead(notificationId));

      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              data: n.data,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
      );
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.markAllNotificationsRead);
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  isRead: true,
                  data: n.data,
                  createdAt: n.createdAt,
                ))
            .toList(),
      );
    } catch (_) {
      // Silently fail
    }
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
    final state = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref
                      .read(notificationProvider.notifier)
                      .loadNotifications(),
                )
              : state.notifications.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () => ref
                          .read(notificationProvider.notifier)
                          .loadNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingSm,
                        ),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.spacingSm),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return _NotificationTile(
                            notification: notification,
                            onTap: () {
                              if (!notification.isRead) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .markAsRead(notification.id);
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'We\'ll notify you when something arrives',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppTheme.card
            : AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: notification.isRead
              ? AppTheme.border
              : AppTheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in colored circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notification.iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 22,
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
                              notification.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
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
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (notification.createdAt != null) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          notification.createdAt!.toTimeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
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
}
