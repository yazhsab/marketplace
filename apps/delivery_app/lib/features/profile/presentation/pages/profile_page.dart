import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);
    final partner = dashState.partner;
    final theme = Theme.of(context);

    final userName = authState is AuthAuthenticated
        ? authState.user.fullName
        : 'Delivery Partner';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // -- Gradient Header with Name --
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTheme.spacingLg,
              bottom: AppTheme.spacing3xl,
              left: AppTheme.spacingXl,
              right: AppTheme.spacingXl,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              children: [
                // App bar row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white, size: 22),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Name
                Text(
                  userName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Status badge
                if (partner != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: partner.status == 'active' ||
                                    partner.status == 'approved'
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          partner.status.capitalize,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // -- Content below header --
          Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXl),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingBase,
                  AppTheme.spacingXl,
                  AppTheme.spacingBase,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- Vehicle Info Section --
                    if (partner != null) ...[
                      _buildSectionTitle(theme, Icons.two_wheeler_outlined,
                          'Vehicle Information'),
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.shadowSm,
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              theme,
                              Icons.two_wheeler,
                              'Vehicle Type',
                              partner.vehicleType.capitalize,
                              AppTheme.primary,
                            ),
                            const Divider(
                                color: AppTheme.border, height: 1),
                            _buildInfoTile(
                              theme,
                              Icons.badge_outlined,
                              'Vehicle Number',
                              partner.vehicleNumber ?? 'Not provided',
                              AppTheme.accent,
                            ),
                            const Divider(
                                color: AppTheme.border, height: 1),
                            _buildInfoTile(
                              theme,
                              Icons.credit_card_outlined,
                              'License Number',
                              partner.licenseNumber ?? 'Not provided',
                              AppTheme.secondary,
                            ),
                            if (partner.zonePreference != null) ...[
                              const Divider(
                                  color: AppTheme.border, height: 1),
                              _buildInfoTile(
                                theme,
                                Icons.location_on_outlined,
                                'Zone Preference',
                                partner.zonePreference!,
                                AppTheme.successColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // -- Performance Metrics Section --
                      _buildSectionTitle(
                          theme, Icons.bar_chart_outlined, 'Performance'),
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.shadowSm,
                        ),
                        child: Column(
                          children: [
                            // Rating with Stars
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                  ),
                                  child: const Icon(Icons.star,
                                      color: AppTheme.secondary, size: 22),
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Average Rating',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: AppTheme.spacingXs),
                                    Row(
                                      children: [
                                        ...List.generate(5, (index) {
                                          final rating = partner.avgRating;
                                          if (index < rating.floor()) {
                                            return const Icon(Icons.star,
                                                color: AppTheme.secondary,
                                                size: 18);
                                          } else if (index < rating) {
                                            return const Icon(
                                                Icons.star_half,
                                                color: AppTheme.secondary,
                                                size: 18);
                                          } else {
                                            return Icon(
                                                Icons.star_outline,
                                                color: AppTheme
                                                    .textTertiary
                                                    .withValues(
                                                        alpha: 0.5),
                                                size: 18);
                                          }
                                        }),
                                        const SizedBox(
                                            width: AppTheme.spacingSm),
                                        Text(
                                          partner.avgRating
                                              .toStringAsFixed(1),
                                          style: theme
                                              .textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingBase),
                            const Divider(color: AppTheme.border),
                            const SizedBox(height: AppTheme.spacingBase),

                            // Stats grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    theme,
                                    icon: Icons.delivery_dining,
                                    label: 'Deliveries',
                                    value:
                                        '${partner.totalDeliveries}',
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppTheme.spacingMd),
                                Expanded(
                                  child: _buildMetricTile(
                                    theme,
                                    icon: Icons.currency_rupee,
                                    label: 'Earnings',
                                    value:
                                        partner.totalEarnings.toPrice,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppTheme.spacingMd),
                                Expanded(
                                  child: _buildMetricTile(
                                    theme,
                                    icon: Icons.percent,
                                    label: 'Commission',
                                    value:
                                        '${partner.commissionPct.toStringAsFixed(0)}%',
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                    ],

                    // -- Account Info Section --
                    if (authState is AuthAuthenticated) ...[
                      _buildSectionTitle(
                          theme, Icons.person_outline, 'Account'),
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.shadowSm,
                        ),
                        child: Column(
                          children: [
                            if (authState.user.email != null)
                              _buildInfoTile(
                                theme,
                                Icons.email_outlined,
                                'Email',
                                authState.user.email!,
                                AppTheme.primary,
                              ),
                            if (authState.user.phone != null) ...[
                              if (authState.user.email != null)
                                const Divider(
                                    color: AppTheme.border, height: 1),
                              _buildInfoTile(
                                theme,
                                Icons.phone_outlined,
                                'Phone',
                                authState.user.phone!,
                                AppTheme.successColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingXl),

                    // -- Logout Button --
                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.error),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  'Logout',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to logout?',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ref
                                          .read(authProvider.notifier)
                                          .logout();
                                      context.go('/login');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.error,
                                    ),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingBase,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout,
                                    color: AppTheme.error, size: 20),
                                const SizedBox(
                                    width: AppTheme.spacingSm),
                                Text(
                                  'Logout',
                                  style:
                                      theme.textTheme.labelLarge?.copyWith(
                                    color: AppTheme.error,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(ThemeData theme, IconData icon, String label,
      String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
