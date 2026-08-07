import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_item.dart';
import '../utils/theme.dart';

/// Modern cart item widget with inline quantity controls
class ModernCartItem extends StatelessWidget {
  final BillItem item;
  final int index;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  const ModernCartItem({
    super.key,
    required this.item,
    required this.index,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final isCollapsible = item.productName.length > 25;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chevron icon for expandable items
          if (isCollapsible)
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 4),
              child: Icon(Icons.chevron_right, size: 16, color: Colors.black54),
            ),

          // Item name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${currency.format(item.rateWithGst)}/${item.unit}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Decrease button
                InkWell(
                  onTap: onDecrease,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: Container(
                    width: 24,
                    height: 32,
                    alignment: Alignment.center,
                    child: Icon(
                      item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                      size: 16,
                      color: item.quantity > 1 ? Colors.black87 : AppTheme.error,
                    ),
                  ),
                ),
                // Quantity display
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      item.quantity % 1 == 0
                          ? item.quantity.toInt().toString()
                          : item.quantity.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Increase button
                InkWell(
                  onTap: onIncrease,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                  child: Container(
                    width: 24,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(item.total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.gstPercent > 0)
                  Text(
                    '${currency.format(item.taxableAmount)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ),

          // Delete button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
