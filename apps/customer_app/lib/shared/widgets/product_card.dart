import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import 'cached_image.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final double? comparePrice;
  final String? imageUrl;
  final double rating;
  final int? reviewCount;
  final String? vendorName;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    this.comparePrice,
    this.imageUrl,
    this.rating = 0,
    this.reviewCount,
    this.vendorName,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = comparePrice != null && comparePrice! > price;
    final discountPercent = hasDiscount
        ? (((comparePrice! - price) / comparePrice!) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/products/$id'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border, width: 1),
          boxShadow: AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge & wishlist
            Stack(
              children: [
                CachedImage(
                  imageUrl: imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: AppTheme.spacingSm,
                    left: AppTheme.spacingSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Wishlist heart
                Positioned(
                  top: AppTheme.spacingSm,
                  right: AppTheme.spacingSm,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),

                  // Vendor
                  if (vendorName != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacingXs),
                      child: Text(
                        vendorName!,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Price row
                  Row(
                    children: [
                      Text(
                        price.toPrice,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          comparePrice!.toPrice,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),

                  // Rating pill + add button
                  if (rating > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
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
                                rating.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($reviewCount)',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                        const Spacer(),
                        if (onAddToCart != null)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
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
