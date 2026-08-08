import 'product.dart';

/// A single line in a bill — no GST, total = price × qty − discount.
class BillItem {
  final String productId;
  final String productName;
  final String unit;
  double       quantity;
  final double rate;           // sale price per unit
  double       discountPercent;
  final double maxStock;       // available stock — 0 means unlimited fallback

  BillItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.rate,
    this.discountPercent = 0,
    this.maxStock = 0,
  });

  // ── Computed ─────────────────────────────────────────────────────────────
  double get grossAmount    => _r(rate * quantity);
  double get discountAmount => _r(grossAmount * discountPercent / 100);
  double get total          => _r(grossAmount - discountAmount);

  // GST not applicable — kept for UI compatibility
  double get rateWithGst   => rate;
  double get gstPercent    => 0.0;
  double get gstAmount     => 0.0;
  double get taxableAmount => total;

  double _r(double v) => double.parse(v.toStringAsFixed(2));

  // ── Factories ─────────────────────────────────────────────────────────────
  factory BillItem.fromProduct(Product p, {double quantity = 1}) => BillItem(
        productId:   p.id,
        productName: p.name,
        unit:        p.unit,
        quantity:    quantity,
        rate:        p.price,
        maxStock:    p.stock,
      );

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        productId:       json['product_id'].toString(),
        productName:     json['product_name'] as String,
        unit:            json['unit'] as String? ?? 'PCS',
        quantity:        (json['quantity'] as num).toDouble(),
        rate:            (json['rate'] as num).toDouble(),
        discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'product_id':       productId,
        'product_name':     productName,
        'unit':             unit,
        'quantity':         quantity,
        'rate':             rate,
        'discount_percent': discountPercent,
      };

  BillItem copyWith({double? quantity, double? discountPercent}) => BillItem(
        productId:       productId,
        productName:     productName,
        unit:            unit,
        quantity:        quantity        ?? this.quantity,
        rate:            rate,
        discountPercent: discountPercent ?? this.discountPercent,
        maxStock:        maxStock,
      );
}
