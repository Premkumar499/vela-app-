import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/billing_provider.dart';
import '../utils/theme.dart';

/// Right-side panel showing GST breakup by slab.
class TaxSummary extends StatelessWidget {
  const TaxSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillingProvider>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final breakup = provider.gstBreakup;

    return Container(
      decoration: AppTheme.panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Tax Summary', style: AppTheme.grandTotalLabel),
              ],
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GST %',
                    style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryDark, fontSize: 12),
                  ),
                ),
                Text(
                  'Tax Amount',
                  style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryDark, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (breakup.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No items added', style: AppTheme.bodySmall),
              ),
            )
          else
            ...breakup.entries.map((entry) {
              return _TaxRow(
                label: entry.key,
                amount: currency.format(entry.value),
              );
            }),
          const Divider(height: 1),
          // Total GST
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Total GST', style: AppTheme.headingSmall),
                ),
                Text(
                  currency.format(provider.gstTotal),
                  style: AppTheme.headingSmall.copyWith(color: AppTheme.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxRow extends StatelessWidget {
  final String label;
  final String amount;

  const _TaxRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.info,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          Text(amount, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}
