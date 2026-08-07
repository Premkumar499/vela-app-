// ============================================================
// INVOICE MODELS
// ============================================================

class InvoiceItem {
  final String description;
  final String hsn;
  final String unit;
  final double qty;
  final double rate;

  InvoiceItem({
    required this.description,
    required this.hsn,
    required this.unit,
    required this.qty,
    required this.rate,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description']?.toString() ?? '',
      hsn: json['hsn']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Pcs',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
    );
  }

  double get amount => qty * rate;
}

class Invoice {
  // Company & Bank Details (Static/Fixed)
  static const String companyName = 'VELA AGENCY';
  static const String companyAddress =
      'Burgur Road, Vellai Pillaiyar Kovil, Anthiyur, Tamil Nadu.';
  static const String companyGstin = '33BAZPM1155J1ZB';
  static const String companyFssai = 'SAMPLE-FSSAI';
  static const String companyPan = 'BAZM115J';
  static const String companyPhone = '+91 986522355';
  static const String companyEmail = 'velaagency27@gmail.com';
  static const String bankName = 'HDFC Bank';
  static const String accountNo = '50200120799532';
  static const String ifsc = 'HDFC0004901';

  // Dynamic fields (supplied via JSON)
  final String invoiceNo;
  final String invoiceDate;
  final String customerName;
  final String customerAddress;
  final String customerGstin;
  final String customerPan;
  final String paymentMode;
  final String txnId;
  final String upiId;
  final List<InvoiceItem> items;

  Invoice({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.customerName,
    required this.customerAddress,
    required this.customerGstin,
    required this.customerPan,
    required this.paymentMode,
    required this.txnId,
    required this.upiId,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final customer = (json['customer'] as Map?)?.cast<String, dynamic>() ?? {};
    final payment = (json['payment'] as Map?)?.cast<String, dynamic>() ?? {};
    final itemsJson = json['items'] as List? ?? [];
    return Invoice(
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      invoiceDate: json['invoiceDate']?.toString() ?? '',
      customerName: customer['name']?.toString() ?? '',
      customerAddress: customer['address']?.toString() ?? '',
      customerGstin: customer['gstin']?.toString() ?? '',
      customerPan: customer['pan']?.toString() ?? '',
      paymentMode: payment['mode']?.toString() ?? '',
      txnId: payment['txnId']?.toString() ?? '',
      upiId: payment['upiId']?.toString() ?? '',
      items: itemsJson
          .map((e) =>
              InvoiceItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  double get totalAmount => items.fold(0, (s, i) => s + i.amount);
}
