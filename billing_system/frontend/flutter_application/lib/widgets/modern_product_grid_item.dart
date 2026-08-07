import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../utils/theme.dart';

/// Modern product card for grid display - inspired by restaurant POS UI
class ModernProductGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ModernProductGridItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    // Dietary indicator colors (simulated based on GST rates for demo)
    Color indicatorColor = Colors.green;
    IconData indicatorIcon = Icons.eco_outlined;
    
    if (product.gst == 0) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.eco_outlined; // Vegan
    } else if (product.gst == 5) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.restaurant_outlined; // Non-veg
    } else if (product.gst >= 18) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.local_fire_department_outlined; // Spicy
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(product.category),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForCategory(product.category),
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                // Dietary indicator badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      indicatorIcon,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Price
                    Text(
                      currency.format(product.priceWithGst),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
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

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return const Color(0xFF4CAF50); // Green
      case 'dairy':
        return const Color(0xFF2196F3); // Blue
      case 'beverages':
        return const Color(0xFFFF9800); // Orange
      case 'snacks':
        return const Color(0xFFE91E63); // Pink
      case 'bakery':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return Icons.shopping_basket;
      case 'dairy':
        return Icons.local_drink;
      case 'beverages':
        return Icons.local_cafe;
      case 'snacks':
        return Icons.cookie;
      case 'bakery':
        return Icons.bakery_dining;
      default:
        return Icons.inventory_2;
    }
  }
}
