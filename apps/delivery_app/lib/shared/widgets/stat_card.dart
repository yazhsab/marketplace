import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Modern stat card with gradient and light variants.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool useGradient;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.onTap,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    if (useGradient) {
      return _buildGradientVariant(theme);
    }
    return _buildLightVariant(theme, effectiveIconColor);
  }

  Widget _buildGradientVariant(ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              value,
              style: theme.textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightVariant(ThemeData theme, Color effectiveIconColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border, width: 1),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, size: 20, color: effectiveIconColor),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
