import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/billing_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// Top information panel displaying bill metadata:
/// Bill Number, Date, Sales Type, Customer, Area, Price List, Through, Remarks.
class TopPanel extends StatelessWidget {
  final String billNumber;
  final String date;

  const TopPanel({
    super.key,
    required this.billNumber,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillingProvider>();

    return Container(
      decoration: AppTheme.panelDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Bill Information', style: AppTheme.grandTotalLabel),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Grid of info fields
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _InfoTile('Bill Number', billNumber, Icons.receipt_long),
              _InfoTile('Date', date, Icons.calendar_today),
              _InfoTile('Sales Type', provider.salesType, Icons.point_of_sale),
              _InfoTile('Payment', provider.paymentType, Icons.payment),
              _InfoTile(
                'Address',
                provider.customer.address.isEmpty ? '—' : provider.customer.address,
                Icons.location_on,
              ),
            ],
          ),
          if (provider.remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoTile('Remarks', provider.remarks, Icons.comment),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
