import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

/// Full-page loading spinner with optional message.
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingWidget({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay loading indicator for async operations.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: LoadingWidget(message: message),
          ),
      ],
    );
  }
}

// ── Skeleton Shimmer Widgets ──────────────────────────────────────────────

/// A single shimmer line placeholder.
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A shimmer card placeholder matching typical card layouts.
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF4),
      highlightColor: const Color(0xFFF5F5FA),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }
}

/// A shimmer list tile placeholder.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF4),
      highlightColor: const Color(0xFFF5F5FA),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 160, height: 14),
                  const SizedBox(height: AppTheme.spacingSm),
                  SkeletonLine(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shimmer grid placeholder for product/service grids.
class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childAspectRatio;

  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    this.childAspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF4),
      highlightColor: const Color(0xFFF5F5FA),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppTheme.spacingBase,
          crossAxisSpacing: AppTheme.spacingBase,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }
}
