import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/booking/presentation/pages/booking_detail_page.dart';
import '../../features/booking/presentation/pages/booking_list_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/order_list_page.dart';
import '../../features/product/presentation/pages/product_form_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/review/presentation/pages/review_list_page.dart';
import '../../features/service/presentation/pages/service_form_page.dart';
import '../../features/service/presentation/pages/service_list_page.dart';
import '../../features/slot/presentation/pages/slot_management_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';

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
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrderListPage(),
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            builder: (context, state) => const BookingListPage(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'walletTab',
            builder: (context, state) => const WalletPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // Product routes
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListPage(),
      ),
      GoRoute(
        path: '/products/add',
        name: 'addProduct',
        builder: (context, state) => const ProductFormPage(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        name: 'editProduct',
        builder: (context, state) => ProductFormPage(
          productId: state.pathParameters['id'],
        ),
      ),

      // Service routes
      GoRoute(
        path: '/services',
        name: 'services',
        builder: (context, state) => const ServiceListPage(),
      ),
      GoRoute(
        path: '/services/add',
        name: 'addService',
        builder: (context, state) => const ServiceFormPage(),
      ),
      GoRoute(
        path: '/services/:id/edit',
        name: 'editService',
        builder: (context, state) => ServiceFormPage(
          serviceId: state.pathParameters['id'],
        ),
      ),

      // Slot management
      GoRoute(
        path: '/slots',
        name: 'slots',
        builder: (context, state) => const SlotManagementPage(),
      ),

      // Order detail
      GoRoute(
        path: '/orders/:id',
        name: 'orderDetail',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
        ),
      ),

      // Booking detail
      GoRoute(
        path: '/bookings/:id',
        name: 'bookingDetail',
        builder: (context, state) => BookingDetailPage(
          bookingId: state.pathParameters['id']!,
        ),
      ),

      // Wallet (full page from profile)
      GoRoute(
        path: '/wallet/full',
        name: 'walletFull',
        builder: (context, state) => const WalletPage(),
      ),

      // Reviews
      GoRoute(
        path: '/reviews',
        name: 'reviews',
        builder: (context, state) => const ReviewListPage(),
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
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/bookings')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/bookings');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
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
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Bookings',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 4,
                  onTap: () => _onItemTapped(4, context),
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
                fontSize: 10,
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
