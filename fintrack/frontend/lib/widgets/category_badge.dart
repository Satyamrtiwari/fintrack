import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  final String type; // 'income' or 'expense'
  final Color? color;

  const CategoryBadge({
    super.key,
    required this.category,
    required this.type,
    this.color,
  });

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('food') || lower.contains('dining') || lower.contains('restaurant')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('transport') || lower.contains('car') || lower.contains('gas')) {
      return Icons.directions_car_rounded;
    } else if (lower.contains('rent') || lower.contains('housing') || lower.contains('home')) {
      return Icons.home_rounded;
    } else if (lower.contains('bill') || lower.contains('utility')) {
      return Icons.receipt_long_rounded;
    } else if (lower.contains('shop')) {
      return Icons.shopping_bag_rounded;
    } else if (lower.contains('entertain') || lower.contains('movie')) {
      return Icons.movie_rounded;
    } else if (lower.contains('health') || lower.contains('med')) {
      return Icons.local_hospital_rounded;
    } else if (lower.contains('edu') || lower.contains('school')) {
      return Icons.school_rounded;
    } else if (lower.contains('salary') || lower.contains('pay')) {
      return Icons.payments_rounded;
    } else if (lower.contains('freelance') || lower.contains('tech')) {
      return Icons.laptop_mac_rounded;
    } else if (lower.contains('invest')) {
      return Icons.trending_up_rounded;
    } else if (lower.contains('gift')) {
      return Icons.card_giftcard_rounded;
    }
    return type.toLowerCase() == 'income'
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = type.toLowerCase() == 'income';
    final badgeColor = color ?? (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(category), size: 14, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
