import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'single_invoice_screen.dart';

/// Displays all saved bills with search and delete support.
class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  List<Bill> _allBills = [];
  List<Bill> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBills();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService.getBills();

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _allBills = result.data!;
        _applyFilter();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result.error;
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allBills.where((b) {
        return query.isEmpty ||
            b.billNumber.toLowerCase().contains(query) ||
            b.customerName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteBill(String billNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Delete bill $billNumber? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await ApiService.deleteBill(billNumber);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          result.success ? 'Bill $billNumber deleted.' : result.error ?? ''),
      backgroundColor: result.success ? AppTheme.success : AppTheme.error,
    ));

    if (result.success) _loadBills();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history, size: 20),
            SizedBox(width: 8),
            Text('Bill History'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by bill number or customer…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBills,
          ),
        ],
      ),
      body: _buildBody(currency),
    );
  }

  Widget _buildBody(NumberFormat currency) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _loadBills,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              _allBills.isEmpty ? 'No bills saved yet.' : 'No results found.',
              style: AppTheme.headingMedium,
            ),
            if (_allBills.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('Create a new bill to see it here.',
                  style: AppTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _BillTile(
          bill: _filtered[i],
          currency: currency,
          onTap: () => Navigator.pushNamed(
            context,
            AppConstants.routeBillDetails,
            arguments: _filtered[i].billNumber,
          ),
          onDelete: () => _deleteBill(_filtered[i].billNumber),
        ),
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BillTile({
    required this.bill,
    required this.currency,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(bill.date);
    final paymentColor = bill.paymentType == 'Cash'
        ? AppTheme.success
        : bill.paymentType == 'Credit'
            ? AppTheme.warning
            : AppTheme.info;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Bill number badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  bill.billNumber.replaceAll('INV', ''),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bill info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bill.billNumber,
                            style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: paymentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            bill.paymentType,
                            style: AppTheme.bodySmall.copyWith(
                              color: paymentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(bill.customerName, style: AppTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(dateStr, style: AppTheme.bodySmall),
                        const SizedBox(width: 12),
                        const Icon(Icons.inventory_2_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${bill.itemCount} items',
                            style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              // Grand total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(bill.grandTotal),
                    style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.business,
                            color: Colors.green, size: 20),
                        onPressed: () {
                          // Navigate to company invoice screen
                          Navigator.pushNamed(
                            context,
                            '/company_invoice',
                            arguments: bill,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Company Invoice',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.error, size: 20),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy  HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}
