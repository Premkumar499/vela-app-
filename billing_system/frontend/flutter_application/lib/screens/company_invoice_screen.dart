import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../models/invoice_model.dart';
import '../widgets/invoice_preview.dart';
import '../services/invoice_export_service.dart';
import '../utils/theme.dart';

/// Professional company invoice with full company details, GSTIN, PAN, bank details
/// Uses the same UI as consolidated invoice
class CompanyInvoiceScreen extends StatefulWidget {
  final Bill bill;

  const CompanyInvoiceScreen({super.key, required this.bill});

  @override
  State<CompanyInvoiceScreen> createState() => _CompanyInvoiceScreenState();
}

class _CompanyInvoiceScreenState extends State<CompanyInvoiceScreen> {
  final GlobalKey _invoiceKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // Convert Bill to Invoice model
    final invoice = _billToInvoice(widget.bill);

    return Scaffold(
      appBar: AppBar(
        title: Text('Company Invoice - ${widget.bill.billNumber}'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _saveInvoice,
              tooltip: 'Save as Image',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: RepaintBoundary(
            key: _invoiceKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              color: Colors.white,
              child: InvoicePreview(invoice: invoice),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    setState(() => _isSaving = true);

    final result = await InvoiceExportService.saveInvoiceAsImage(
      widgetKey: _invoiceKey,
      invoiceNumber: widget.bill.billNumber,
      isCompanyInvoice: true,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final size = (result['size'] as int) / 1024; // Convert to KB
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved: ${result['folder']}/${result['fileName']}\n'
            'Size: ${size.toStringAsFixed(1)} KB'
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Failed to save invoice'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Invoice _billToInvoice(Bill bill) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final billDate = DateTime.tryParse(bill.date) ?? DateTime.now();
    
    // Convert bill items to invoice items (without HSN)
    final invoiceItems = bill.items.map((item) {
      return InvoiceItem(
        description: '${item.productName}\nUnit: ${item.unit}',
        hsn: '', // Hide HSN
        unit: item.unit,
        qty: item.quantity,
        rate: item.rate,
      );
    }).toList();

    return Invoice(
      invoiceNo: bill.billNumber,
      invoiceDate: dateFormat.format(billDate),
      customerName: bill.customerName,
      customerAddress: bill.customerPhone.isNotEmpty 
          ? 'Phone: ${bill.customerPhone}' 
          : 'Walk-in Customer',
      customerGstin: '', // Hide GSTIN
      customerPan: '', // Hide PAN
      paymentMode: bill.paymentType,
      txnId: bill.billNumber,
      upiId: bill.paymentType == 'UPI' ? 'sample@upi' : 'N/A',
      items: invoiceItems,
    );
  }
}
