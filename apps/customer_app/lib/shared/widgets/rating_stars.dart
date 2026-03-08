import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showLabel;
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.color,
    this.showLabel = false,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber.shade600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          if (rating >= starValue) {
            return Icon(Icons.star, size: size, color: starColor);
          } else if (rating >= starValue - 0.5) {
            return Icon(Icons.star_half, size: size, color: starColor);
          } else {
            return Icon(Icons.star_border, size: size, color: starColor);
          }
        }),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.65,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}
