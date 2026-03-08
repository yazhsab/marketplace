import 'package:flutter/material.dart';

/// Modern pill-shaped status badge with dot indicator.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_confirmation':
        return const Color(0xFFF59E0B); // Amber
      case 'confirmed':
      case 'accepted':
        return const Color(0xFF3B82F6); // Blue
      case 'preparing':
      case 'in_progress':
      case 'processing':
        return const Color(0xFF8B5CF6); // Purple
      case 'ready':
      case 'ready_for_pickup':
        return const Color(0xFF14B8A6); // Teal
      case 'assigned':
      case 'out_for_delivery':
      case 'dispatched':
        return const Color(0xFF6366F1); // Indigo
      case 'delivered':
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'refunded':
        return const Color(0xFFF59E0B); // Amber
      case 'active':
      case 'online':
      case 'approved':
      case 'verified':
        return const Color(0xFF10B981); // Emerald
      case 'inactive':
      case 'offline':
        return const Color(0xFF9CA3AF); // Gray
      case 'suspended':
        return const Color(0xFFEF4444); // Red
      case 'pending_verification':
      case 'under_review':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  String get _displayText {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _displayText,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
