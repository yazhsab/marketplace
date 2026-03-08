import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- Gradient Header ---
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingXl,
                  AppTheme.spacingBase,
                  AppTheme.spacingXl,
                  AppTheme.spacing2xl,
                ),
                child: Column(
                  children: [
                    // Top bar row
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
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: Colors.white, size: 22),
                            onPressed: () {},
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Avatar + Name
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
                      child: Center(
                        child: Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName[0].toUpperCase()
                              : 'V',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      user?.fullName ?? 'Vendor',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        user!.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    if (user?.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.phone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // --- Menu Sections ---
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Section
                _buildSectionTitle(context, 'Business'),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.inventory_2_rounded,
                        label: 'Products',
                        iconBgColor: const Color(0xFF3B82F6),
                        onTap: () => context.push('/products'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildMenuItem(
                        context,
                        icon: Icons.design_services_rounded,
                        label: 'Services',
                        iconBgColor: const Color(0xFF8B5CF6),
                        onTap: () => context.push('/services'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildMenuItem(
                        context,
                        icon: Icons.event_available_rounded,
                        label: 'Manage Slots',
                        iconBgColor: const Color(0xFF14B8A6),
                        onTap: () => context.push('/slots'),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Finance Section
                _buildSectionTitle(context, 'Finance'),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Wallet',
                        iconBgColor: AppTheme.successColor,
                        onTap: () => context.push('/wallet/full'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildMenuItem(
                        context,
                        icon: Icons.star_rounded,
                        label: 'Reviews',
                        iconBgColor: AppTheme.warningColor,
                        onTap: () => context.push('/reviews'),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Account Section
                _buildSectionTitle(context, 'Account'),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        iconBgColor: AppTheme.secondary,
                        onTap: () => context.push('/notifications'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        iconBgColor: const Color(0xFF6366F1),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        iconBgColor: AppTheme.textTertiary,
                        onTap: () {},
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Logout
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      onTap: () => _showLogoutDialog(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingBase,
                          vertical: AppTheme.spacingMd,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: const Icon(Icons.logout_rounded,
                                  color: AppTheme.error, size: 20),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Text(
                              'Logout',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.spacingXs),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textTertiary,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusLg),
                bottomRight: Radius.circular(AppTheme.radiusLg),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingMd,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: iconBgColor, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
