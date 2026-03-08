import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import 'cached_image.dart';

class ServiceCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final String? imageUrl;
  final double rating;
  final int? reviewCount;
  final String? vendorName;

  const ServiceCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.imageUrl,
    this.rating = 0,
    this.reviewCount,
    this.vendorName,
  });

  String get _formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/services/$id'),
      child: Container(
        width: 220,
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
            // Image
            CachedImage(
              imageUrl: imageUrl,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
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
                  Row(
                    children: [
                      Text(
                        price.toPrice,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formattedDuration,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
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
