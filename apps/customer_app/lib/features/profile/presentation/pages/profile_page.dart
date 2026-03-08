import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header Card ──────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingXl,
                    bottom: AppTheme.spacing2xl,
                    left: AppTheme.spacingBase,
                    right: AppTheme.spacingBase,
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: CachedImage(
                                  imageUrl: user!.avatarUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: AppTheme.primary,
                              ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // Name
                      Text(
                        user?.fullName ?? 'User',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      // Email
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      // Phone
                      if (user?.phone != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: AppTheme.spacingXs),
                          child: Text(
                            user!.phone!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats Row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
                vertical: AppTheme.spacingLg,
              ),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    count: '0',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  _StatCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bookings',
                    count: '0',
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  _StatCard(
                    icon: Icons.star_outline,
                    label: 'Reviews',
                    count: '0',
                    color: AppTheme.accent,
                  ),
                ],
              ),
            ),

            // ── Account Section ───────────────────────────────────────────
            _SectionTitle(title: 'Account'),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.person_outline,
                    iconColor: AppTheme.primary,
                    title: 'Edit Profile',
                    onTap: () {
                      // Navigate to edit profile
                    },
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFFE17055),
                    title: 'My Addresses',
                    onTap: () {
                      // Navigate to addresses
                    },
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    icon: Icons.receipt_long_outlined,
                    iconColor: const Color(0xFF0984E3),
                    title: 'Order History',
                    onTap: () => context.go('/orders'),
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppTheme.secondary,
                    title: 'My Bookings',
                    onTap: () => context.push('/bookings'),
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFE84393),
                    title: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    icon: Icons.star_outline,
                    iconColor: const Color(0xFFF39C12),
                    title: 'My Reviews',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Support Section ───────────────────────────────────────────
            _SectionTitle(title: 'Support'),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF6C5CE7),
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    icon: Icons.info_outline,
                    iconColor: AppTheme.textSecondary,
                    title: 'About',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Logout ────────────────────────────────────────────────────
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowSm,
              ),
              child: _ProfileMenuItem(
                icon: Icons.logout,
                iconColor: AppTheme.error,
                title: 'Logout',
                titleColor: AppTheme.error,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content:
                          const Text('Are you sure you want to log out?'),
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
                          child: const Text('Logout',
                              style: TextStyle(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppTheme.spacing2xl),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMd,
          horizontal: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              count,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingBase,
        right: AppTheme.spacingBase,
        bottom: AppTheme.spacingSm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Menu Divider ──────────────────────────────────────────────────────────────
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.border,
      indent: 56,
      endIndent: 0,
    );
  }
}

// ── Profile Menu Item ─────────────────────────────────────────────────────────
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
          child: Row(
            children: [
              // Icon in colored circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              // Label
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? AppTheme.textPrimary,
                  ),
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
