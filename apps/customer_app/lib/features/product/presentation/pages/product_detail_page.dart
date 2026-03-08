import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../providers/product_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
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
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: productAsync.when(
        loading: () => const _ProductDetailSkeleton(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
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
                          height: 380,
                          child: product.images.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: product.images.length,
                                  onPageChanged: (index) {
                                    setState(
                                        () => _currentImageIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return CachedImage(
                                      imageUrl: product.images[index],
                                      width: double.infinity,
                                      height: 380,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Container(
                                  height: 380,
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppTheme.border,
                                        AppTheme.border.withValues(alpha: 0.6),
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
                                      child: const Icon(Icons.image_outlined,
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
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.15),
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
                                  Row(
                                    children: [
                                      _CircleIconButton(
                                        icon: Icons.share_outlined,
                                        onPressed: () {},
                                      ),
                                      const SizedBox(
                                          width: AppTheme.spacingSm),
                                      _CircleIconButton(
                                        icon: Icons.shopping_cart_outlined,
                                        onPressed: () =>
                                            context.push('/cart'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Discount badge
                        if (product.hasDiscount)
                          Positioned(
                            top: 100,
                            left: AppTheme.spacingBase,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                                vertical: AppTheme.spacingXs + 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.error.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${product.discountPercent}% OFF',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Dots indicator (smooth elongated)
                        if (product.images.length > 1)
                          Positioned(
                            bottom: 28,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product.images.length,
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
                              // Product name
                              Text(
                                product.name,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMd),

                              // Price row + stock badge
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  // Price
                                  Text(
                                    product.price.toPrice,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  if (product.hasDiscount) ...[
                                    const SizedBox(
                                        width: AppTheme.spacingMd),
                                    Text(
                                      product.comparePrice!.toPrice,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: AppTheme.textTertiary,
                                        decoration:
                                            TextDecoration.lineThrough,
                                        decorationColor: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  // Stock pill badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingMd,
                                      vertical: AppTheme.spacingXs + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.inStock
                                          ? AppTheme.secondary
                                              .withValues(alpha: 0.1)
                                          : AppTheme.error
                                              .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.radiusFull),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          product.inStock
                                              ? Icons.check_circle_outline
                                              : Icons.cancel_outlined,
                                          size: 14,
                                          color: product.inStock
                                              ? AppTheme.secondary
                                              : AppTheme.error,
                                        ),
                                        const SizedBox(width: AppTheme.spacingXs),
                                        Text(
                                          product.inStock
                                              ? 'In Stock'
                                              : 'Out of Stock',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: product.inStock
                                                ? AppTheme.secondary
                                                : AppTheme.error,
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
                              if (product.rating > 0) ...[
                                RatingStars(
                                  rating: product.rating,
                                  size: 20,
                                  showLabel: true,
                                  reviewCount: product.reviewCount,
                                ),
                                const SizedBox(height: AppTheme.spacingLg),
                              ],

                              const Divider(color: AppTheme.border),
                              const SizedBox(height: AppTheme.spacingBase),

                              // -- Vendor Row --
                              if (product.vendorName != null) ...[
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
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.store_rounded,
                                          color: AppTheme.primary,
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
                                              product.vendorName!,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Sold by',
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
                                            '/vendors/${product.vendorId}'),
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
                                            product.description.isNotEmpty
                                                ? product.description
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
                              const SizedBox(height: AppTheme.spacingBase),
                              const Divider(color: AppTheme.border),
                              const SizedBox(height: AppTheme.spacingBase),

                              // -- Reviews Section --
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reviews',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'See All',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppTheme.spacing2xl),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.rate_review_outlined,
                                      size: 36,
                                      color: AppTheme.textTertiary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: AppTheme.spacingSm),
                                    Text(
                                      'No reviews yet',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom spacing for sticky bar
                              const SizedBox(height: 80),
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
                                product.price.toPrice,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppTheme.spacingBase),
                          // Add to Cart button
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: product.inStock
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: product.inStock
                                    ? null
                                    : AppTheme.textTertiary,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLg),
                                boxShadow: product.inStock
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: product.inStock
                                      ? () {
                                          ref
                                              .read(
                                                  cartProvider.notifier)
                                              .addItem(
                                                CartItem(
                                                  productId: product.id,
                                                  name: product.name,
                                                  price: product.price,
                                                  quantity: 1,
                                                  image: product
                                                          .images
                                                          .isNotEmpty
                                                      ? product
                                                          .images.first
                                                      : null,
                                                  vendorId:
                                                      product.vendorId,
                                                ),
                                              );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Added to cart'),
                                              action: SnackBarAction(
                                                label: 'View Cart',
                                                onPressed: () =>
                                                    context.push('/cart'),
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLg),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(
                                            width: AppTheme.spacingSm),
                                        Text(
                                          product.inStock
                                              ? 'Add to Cart'
                                              : 'Out of Stock',
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

// -- Skeleton Shimmer for Product Detail loading --
class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

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
              height: 380,
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
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Price row
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
                        const Spacer(),
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
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Container(
                          height: 12,
                          width: index == 3 ? 180 : double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
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
