import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../providers/service_provider.dart';

class ServiceDetailPage extends ConsumerStatefulWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  int _currentImageIndex = 0;
  final _pageController = PageController();
  bool _descriptionExpanded = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: serviceAsync.when(
        loading: () => const _ServiceDetailSkeleton(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(serviceDetailProvider(widget.serviceId)),
        ),
        data: (service) {
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // -- Hero Image with PageView --
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Image carousel
                        SizedBox(
                          height: 350,
                          child: service.images.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: service.images.length,
                                  onPageChanged: (index) {
                                    setState(
                                        () => _currentImageIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return CachedImage(
                                      imageUrl: service.images[index],
                                      width: double.infinity,
                                      height: 350,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Container(
                                  height: 350,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppTheme.primary.withValues(alpha: 0.08),
                                        AppTheme.primary.withValues(alpha: 0.15),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.handyman_outlined,
                                          size: 56,
                                          color: AppTheme.textTertiary),
                                    ),
                                  ),
                                ),
                        ),

                        // Gradient overlay at bottom of image
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Top bar overlay
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: AppTheme.spacingSm,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CircleIconButton(
                                    icon: Icons.arrow_back,
                                    onPressed: () => context.pop(),
                                  ),
                                  _CircleIconButton(
                                    icon: Icons.share_outlined,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Dots indicator (smooth elongated)
                        if (service.images.length > 1)
                          Positioned(
                            bottom: 28,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                service.images.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: _currentImageIndex == index
                                      ? 28
                                      : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? AppTheme.primary
                                        : Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                    boxShadow: _currentImageIndex == index
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // -- Content Card overlapping image --
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusXl + 4),
                          ),
                          boxShadow: AppTheme.shadowMd,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingXl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Service name
                              Text(
                                service.name,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (service.vendorName != null) ...[
                                const SizedBox(height: AppTheme.spacingXs),
                                Text(
                                  'by ${service.vendorName}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppTheme.spacingBase),

                              // Price + duration row
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    service.price.toPrice,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: AppTheme.spacingMd),
                                  // Duration pill (green bg)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingMd,
                                      vertical: AppTheme.spacingXs + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.radiusFull),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule_rounded,
                                            size: 15,
                                            color: AppTheme.secondary),
                                        const SizedBox(width: AppTheme.spacingXs),
                                        Text(
                                          service.formattedDuration,
                                          style: theme
                                              .textTheme.labelMedium
                                              ?.copyWith(
                                            color: AppTheme.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingBase),

                              // Rating
                              if (service.rating > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingSm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: RatingStars(
                                    rating: service.rating,
                                    size: 20,
                                    showLabel: true,
                                    reviewCount: service.reviewCount,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingLg),
                              ],

                              const Divider(color: AppTheme.border),
                              const SizedBox(height: AppTheme.spacingBase),

                              // -- Vendor Row --
                              if (service.vendorName != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.store_rounded,
                                          color: AppTheme.secondary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppTheme.spacingMd),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service.vendorName!,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Service Provider',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color:
                                                    AppTheme.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.push(
                                            '/vendors/${service.vendorId}'),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Visit Store',
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: AppTheme.spacingXs),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: AppTheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingBase),
                                const Divider(color: AppTheme.border),
                                const SizedBox(height: AppTheme.spacingBase),
                              ],

                              // -- Description (expandable) --
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _descriptionExpanded =
                                        !_descriptionExpanded;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Description',
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          AnimatedRotation(
                                            turns: _descriptionExpanded ? 0.5 : 0,
                                            duration: const Duration(milliseconds: 200),
                                            child: Container(
                                              padding: const EdgeInsets.all(AppTheme.spacingXs),
                                              decoration: BoxDecoration(
                                                color: AppTheme.border,
                                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                              ),
                                              child: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: AppTheme.textSecondary,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      AnimatedCrossFade(
                                        firstChild: const SizedBox.shrink(),
                                        secondChild: Padding(
                                          padding: const EdgeInsets.only(
                                              top: AppTheme.spacingSm),
                                          child: Text(
                                            service.description.isNotEmpty
                                                ? service.description
                                                : 'No description available.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: AppTheme.textSecondary,
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                        crossFadeState: _descriptionExpanded
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        duration: const Duration(milliseconds: 200),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // -- Available Days --
                              if (service.availableDays.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingBase),
                                const Divider(color: AppTheme.border),
                                const SizedBox(height: AppTheme.spacingBase),
                                Text(
                                  'Available Days',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                Wrap(
                                  spacing: AppTheme.spacingSm,
                                  runSpacing: AppTheme.spacingSm,
                                  children:
                                      service.availableDays.map((day) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingMd,
                                        vertical: AppTheme.spacingXs + 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppTheme.radiusFull),
                                        border: Border.all(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 14,
                                            color: AppTheme.primaryDark.withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: AppTheme.spacingXs),
                                          Text(
                                            day,
                                            style: theme
                                                .textTheme.labelMedium
                                                ?.copyWith(
                                              color: AppTheme.primaryDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Bottom spacing for sticky bar
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // -- Sticky Bottom Bar --
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    border: const Border(
                      top: BorderSide(color: AppTheme.border, width: 1),
                    ),
                    boxShadow: AppTheme.shadowMd,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingBase,
                        vertical: AppTheme.spacingMd,
                      ),
                      child: Row(
                        children: [
                          // Price on the left
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Price',
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service.price.toPrice,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppTheme.spacingBase),
                          // Book Now button
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => context.push(
                                      '/booking/new/${widget.serviceId}'),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLg),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(
                                            width: AppTheme.spacingSm),
                                        Text(
                                          'Book Now',
                                          style: theme
                                              .textTheme.labelLarge
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -- Skeleton Shimmer for Service Detail loading --
class _ServiceDetailSkeleton extends StatelessWidget {
  const _ServiceDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF4),
      highlightColor: const Color(0xFFF5F5FA),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.white,
            ),
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl + 4),
                  ),
                ),
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      height: 24,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Price + duration row
                    Row(
                      children: [
                        Container(
                          height: 28,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Container(
                          height: 28,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    // Vendor row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    // Description lines
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Container(
                          height: 12,
                          width: index == 2 ? 150 : double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Day pills
                    Row(
                      children: List.generate(
                        4,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                          child: Container(
                            height: 30,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Circle Icon Button (for top bar overlay) --
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
