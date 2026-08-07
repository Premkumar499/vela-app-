import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../utils/theme.dart';

/// Customer card for the customer selection screen.
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: isSelected
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTheme.headingSmall),
                    const SizedBox(height: 4),
                    if (customer.phone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(customer.phone, style: AppTheme.bodySmall),
                        ],
                      ),
                    if (customer.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Area badge
              if (customer.area.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tableHeaderColor, // Blue 50 colour constant
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    customer.area,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primary)
              else
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
