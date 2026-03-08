import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/order/presentation/pages/order_list_page.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/checkout_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/service/presentation/pages/service_detail_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/booking/presentation/pages/booking_create_page.dart';
import '../../features/booking/presentation/pages/booking_list_page.dart';
import '../../features/booking/presentation/pages/booking_detail_page.dart';
import '../../features/notification/presentation/pages/notification_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/otp';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/';
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
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
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

      // Main shell route with bottom nav
      ShellRoute(
        builder: (context, state, child) {
          return _MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrderListPage(),
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
        path: '/products/:id',
        name: 'productDetail',
        builder: (context, state) => ProductDetailPage(
          productId: state.pathParameters['id']!,
        ),
      ),

      // Service routes
      GoRoute(
        path: '/services/:id',
        name: 'serviceDetail',
        builder: (context, state) => ServiceDetailPage(
          serviceId: state.pathParameters['id']!,
        ),
      ),

      // Cart
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),

      // Checkout
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),

      // Order detail
      GoRoute(
        path: '/orders/:id',
        name: 'orderDetail',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
        ),
      ),

      // Booking routes
      GoRoute(
        path: '/booking/new/:serviceId',
        name: 'bookingCreate',
        builder: (context, state) => BookingCreatePage(
          serviceId: state.pathParameters['serviceId']!,
        ),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingListPage(),
      ),
      GoRoute(
        path: '/bookings/:id',
        name: 'bookingDetail',
        builder: (context, state) => BookingDetailPage(
          bookingId: state.pathParameters['id']!,
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
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/orders');
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  label: 'Search',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
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
