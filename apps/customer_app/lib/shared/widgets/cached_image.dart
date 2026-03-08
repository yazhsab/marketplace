import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final widget = imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) => _buildError(),
          )
        : _buildError();

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: widget,
      );
    }
    return widget;
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF4),
      highlightColor: const Color(0xFFF5F5FA),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textTertiary,
        size: 32,
      ),
    );
  }
}
