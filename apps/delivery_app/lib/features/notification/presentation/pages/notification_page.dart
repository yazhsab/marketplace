import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationState {
  final bool isLoading;
  final String? error;
  final List<NotificationItem> notifications;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    List<NotificationItem>? notifications,
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
                NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(ApiEndpoints.markNotificationRead(id));
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == id
                ? NotificationItem(
                    id: n.id,
                    title: n.title,
                    body: n.body,
                    type: n.type,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n)
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(ApiEndpoints.markAllNotificationsRead);
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notifState.notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifState.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              itemCount: 5,
              itemBuilder: (_, _) => const Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: SkeletonListTile(),
              ),
            )
          : notifState.error != null && notifState.notifications.isEmpty
              ? AppErrorWidget(
                  message: notifState.error!,
                  onRetry: () => ref
                      .read(notificationProvider.notifier)
                      .loadNotifications(),
                )
              : notifState.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 40,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          Text(
                            'No notifications yet',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'You\'ll see delivery updates here',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () => ref
                          .read(notificationProvider.notifier)
                          .loadNotifications(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        itemCount: notifState.notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifState.notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingSm),
                            child: _buildNotificationTile(
                                context, ref, notif, theme),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WidgetRef ref,
      NotificationItem notif, ThemeData theme) {
    final iconColor = _getIconColor(notif.type);

    return Container(
      decoration: BoxDecoration(
        color: notif.isRead
            ? AppTheme.card
            : AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: notif.isRead
              ? AppTheme.border
              : AppTheme.primary.withValues(alpha: 0.15),
        ),
        boxShadow: notif.isRead ? null : AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () {
            if (!notif.isRead) {
              ref.read(notificationProvider.notifier).markAsRead(notif.id);
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
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    _getIcon(notif.type),
                    color: iconColor,
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
                              notif.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          // Unread dot
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
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.textTertiary,
                          ),
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

  IconData _getIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.delivery_dining_rounded;
      case 'order':
        return Icons.receipt_long_rounded;
      case 'earnings':
        return Icons.currency_rupee_rounded;
      case 'account':
        return Icons.person_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'assignment':
        return AppTheme.primary;
      case 'order':
        return AppTheme.secondary;
      case 'earnings':
        return AppTheme.successColor;
      case 'account':
        return AppTheme.accent;
      default:
        return AppTheme.textTertiary;
    }
  }
}
