import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/service_card.dart';
import '../providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: homeState.isLoading
          ? _buildSkeletonLoading()
          : homeState.error != null
              ? AppErrorWidget(
                  message: homeState.error!,
                  onRetry: () =>
                      ref.read(homeProvider.notifier).loadHomeData(),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () =>
                      ref.read(homeProvider.notifier).loadHomeData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).padding.top +
                                AppTheme.spacingBase),

                        // Greeting + Notification bell
                        _buildGreetingHeader(context, theme),

                        const SizedBox(height: AppTheme.spacingLg),

                        // Search Bar
                        _buildSearchBar(context, theme),

                        const SizedBox(height: AppTheme.spacingXl),

                        // Categories
                        if (homeState.categories.isNotEmpty)
                          _buildCategories(context, theme, homeState),

                        // Nearby Vendors
                        if (homeState.nearbyVendors.isNotEmpty)
                          _buildNearbyVendors(context, theme, homeState),

                        // Popular Products
                        if (homeState.popularProducts.isNotEmpty)
                          _buildPopularProducts(context, theme, homeState),

                        // Top Services
                        if (homeState.topServices.isNotEmpty)
                          _buildTopServices(context, theme, homeState),

                        const SizedBox(height: AppTheme.spacing2xl),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Skeleton Loading ──────────────────────────────────────────────────

  Widget _buildSkeletonLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingSm),
            // Greeting skeleton
            const SkeletonCard(height: 28),
            const SizedBox(height: AppTheme.spacingLg),
            // Search bar skeleton
            const SkeletonCard(height: 48),
            const SizedBox(height: AppTheme.spacingXl),
            // Categories skeleton
            const SkeletonCard(height: 90),
            const SizedBox(height: AppTheme.spacingXl),
            // Vendor cards skeleton
            const SkeletonCard(height: 180),
            const SizedBox(height: AppTheme.spacingXl),
            // Product grid skeleton
            SkeletonGrid(
              crossAxisCount: 2,
              itemCount: 4,
              childAspectRatio: 0.68,
            ),
          ],
        ),
      ),
    );
  }

  // ── Greeting Header ───────────────────────────────────────────────────

  Widget _buildGreetingHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()} \u{1F44B}',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'What are you looking for today?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          // Notification bell with red dot badge
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.spacingXl),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Search products, services, vendors...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Categories (circular icons) ───────────────────────────────────────

  Widget _buildCategories(
      BuildContext context, ThemeData theme, HomeState state) {
    // Color palette for category circles
    const categoryColors = [
      Color(0xFFEDE9FE), // light violet
      Color(0xFFD1FAE5), // light green
      Color(0xFFFEF3C7), // light amber
      Color(0xFFFFE4E6), // light rose
      Color(0xFFDBEAFE), // light blue
      Color(0xFFFCE7F3), // light pink
      Color(0xFFCCFBF1), // light teal
      Color(0xFFFEF9C3), // light yellow
    ];

    const categoryIcons = [
      Icons.category_rounded,
      Icons.restaurant_rounded,
      Icons.local_grocery_store_rounded,
      Icons.checkroom_rounded,
      Icons.devices_rounded,
      Icons.home_repair_service_rounded,
      Icons.spa_rounded,
      Icons.sports_esports_rounded,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, theme, 'Categories'),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase),
            itemCount: state.categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingBase),
            itemBuilder: (context, index) {
              final category = state.categories[index];
              final bgColor =
                  categoryColors[index % categoryColors.length];
              final icon =
                  categoryIcons[index % categoryIcons.length];

              return GestureDetector(
                onTap: () =>
                    context.go('/search?category=${category.id}'),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 26,
                          color: AppTheme.textPrimary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  // ── Nearby Vendors ────────────────────────────────────────────────────

  Widget _buildNearbyVendors(
      BuildContext context, ThemeData theme, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, theme, 'Nearby Vendors',
            onSeeAll: () {}),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase),
            itemCount: state.nearbyVendors.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingMd),
            itemBuilder: (context, index) {
              final vendor = state.nearbyVendors[index];
              return _VendorCard(vendor: vendor);
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  // ── Popular Products ──────────────────────────────────────────────────

  Widget _buildPopularProducts(
      BuildContext context, ThemeData theme, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, theme, 'Popular Products',
            onSeeAll: () {}),
        const SizedBox(height: AppTheme.spacingMd),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: AppTheme.spacingMd,
              mainAxisSpacing: AppTheme.spacingMd,
            ),
            itemCount: state.popularProducts.length.clamp(0, 6),
            itemBuilder: (context, index) {
              final product = state.popularProducts[index];
              return ProductCard(
                id: product.id,
                name: product.name,
                price: product.price,
                comparePrice: product.comparePrice,
                imageUrl: product.images.isNotEmpty
                    ? product.images.first
                    : null,
                rating: product.rating,
                reviewCount: product.reviewCount,
                vendorName: product.vendorName,
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  // ── Top Services ──────────────────────────────────────────────────────

  Widget _buildTopServices(
      BuildContext context, ThemeData theme, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, theme, 'Top Services',
            onSeeAll: () {}),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase),
            itemCount: state.topServices.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingMd),
            itemBuilder: (context, index) {
              final service = state.topServices[index];
              return ServiceCard(
                id: service.id,
                name: service.name,
                price: service.price,
                durationMinutes: service.durationMinutes,
                imageUrl: service.images.isNotEmpty
                    ? service.images.first
                    : null,
                rating: service.rating,
                reviewCount: service.reviewCount,
                vendorName: service.vendorName,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Vendor Card (160w, rounded image, name, rating pill, distance) ──────

class _VendorCard extends StatelessWidget {
  final VendorSummary vendor;

  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/vendors/${vendor.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor image
            CachedImage(
              imageUrl: vendor.logoUrl,
              height: 100,
              width: 160,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),

            // Vendor details
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),

                  // Rating pill + distance
                  Row(
                    children: [
                      if (vendor.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (vendor.rating > 0 && vendor.distance != null)
                        const SizedBox(width: AppTheme.spacingSm),
                      if (vendor.distance != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${vendor.distance!.toStringAsFixed(1)} km',
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
