/// Product model — no GST, plain sale price.
class Product {
  final int id;
  final String name;
  final String unit;
  final double price;   // final sale price (no tax)
  final double mrp;
  final double stock;
  final String category;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.mrp,
    required this.stock,
    required this.category,
    this.description = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id:          json['id'] as int,
      name:        json['name'] as String,
      unit:        json['unit'] as String,
      price:       (json['price'] as num).toDouble(),
      mrp:         (json['mrp'] as num).toDouble(),
      stock:       (json['stock'] as num).toDouble(),
      category:    json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
        'mrp': mrp,
        'stock': stock,
        'category': category,
        'description': description,
      };

  // ── Computed (GST not applicable — kept for UI compatibility) ────────────
  double get gst         => 0.0;           // no GST in this system
  double get priceWithGst => price;        // price is already the final price

  @override
  String toString() => 'Product($id, $name)';
}
