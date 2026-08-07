// ============================================================
// SINGLE INVOICE SCREEN
// Shows a single bill in professional invoice format
// ============================================================

import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/invoice_model.dart';
import '../widgets/invoice_preview.dart';

class SingleInvoiceScreen extends StatelessWidget {
  final Bill bill;

  const SingleInvoiceScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    // Convert Bill to Invoice
    final invoice = _convertBillToInvoice(bill);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${bill.billNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () {
              // TODO: Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: InvoicePreview(invoice: invoice),
      ),
    );
  }

  Invoice _convertBillToInvoice(Bill bill) {
    // Convert bill items to invoice items
    final invoiceItems = bill.items.map((item) {
      return InvoiceItem(
        description: item.productName,
        hsn: '0000', // HSN not available in current system
        unit: item.unit,
        qty: item.quantity,
        rate: item.rate,
      );
    }).toList();

    // Format date
    final dateTime = DateTime.parse(bill.date);
    final formattedDate = _formatDate(dateTime);

    return Invoice(
      invoiceNo: bill.billNumber,
      invoiceDate: formattedDate,
      customerName: bill.customerName,
      customerAddress: _getCustomerAddress(bill),
      customerGstin: 'N/A',
      customerPan: 'N/A',
      paymentMode: bill.paymentType,
      txnId: bill.remarks.isNotEmpty ? bill.remarks : 'N/A',
      upiId: bill.paymentType.toUpperCase() == 'UPI' ? 'Available' : 'N/A',
      items: invoiceItems,
    );
  }

  String _getCustomerAddress(Bill bill) {
    final parts = <String>[];
    if (bill.area.isNotEmpty) parts.add(bill.area);
    parts.add('Tamil Nadu, India');
    return parts.join(', ');
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
