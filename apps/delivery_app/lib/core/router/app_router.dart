import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assignment/presentation/pages/assignment_detail_page.dart';
import '../../features/assignment/presentation/pages/assignment_list_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/earnings/presentation/pages/earnings_page.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      if (isAuthenticated && isOnboardingRoute) {
        return null;
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpPage(
            phone: extra['phone'] as String? ?? '',
            verificationId: extra['verificationId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Main shell route with bottom nav
      ShellRoute(
        builder: (context, state, child) {
          return _MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/assignments',
            name: 'assignments',
            builder: (context, state) => const AssignmentListPage(),
          ),
          GoRoute(
            path: '/earnings',
            name: 'earnings',
            builder: (context, state) => const EarningsPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // Assignment detail
      GoRoute(
        path: '/assignments/:id',
        name: 'assignmentDetail',
        builder: (context, state) => AssignmentDetailPage(
          assignmentId: state.pathParameters['id']!,
        ),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationPage(),
      ),
    ],
  );
});

class _MainScaffold extends StatelessWidget {
  final Widget child;

  const _MainScaffold({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/assignments')) return 1;
    if (location.startsWith('/earnings')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/assignments');
        break;
      case 2:
        context.go('/earnings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.delivery_dining_outlined,
                  activeIcon: Icons.delivery_dining_rounded,
                  label: 'Deliveries',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Earnings',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? theme.colorScheme.primary
        : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
