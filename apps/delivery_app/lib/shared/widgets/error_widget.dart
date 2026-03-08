import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Error state with retry action.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.error.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state with icon, message, and optional action.
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: actionIcon != null
                    ? Icon(actionIcon, size: 18)
                    : const SizedBox.shrink(),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
