# 7. Frontend — Models

Location: `billing_system/frontend/flutter_application/lib/models/`

All models are plain Dart classes with `fromJson` factories and `toJson` serialisers.
The system is **non-GST**, so GST getters are present only for UI compatibility and
always return `0`.

## 7.1 `Product` — `models/product.dart`

```dart
class Product {
  final String id;
  final String name;
  final String unit;       // KG, PCS, LTR, PKT, CASE, Bag, Nos…
  final double price;      // final sale price (no tax)
  final double mrp;
  final double stock;
  final String category;
  final String description;
  final String? imageUrl;
}
```

- `Product.fromJson(Map)` — maps the Flask response fields (`price`, `mrp`, `stock`
  as numbers, `image_url` nullable).
- `toJson()` — reverse mapping.
- Computed: `gst => 0.0`, `priceWithGst => price` (no GST).

## 7.2 `Customer` — `models/customer.dart`

```dart
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String area;
  final String gstin;
  final double creditLimit;
  final double balance;
}
```

- `Customer.fromJson` / `toJson` as above.
- **`Customer.walkIn`** — static singleton:
  ```dart
  Customer(id: '00000000-0000-0000-0000-000000000000',
           name: 'Walk-in Customer', area: 'General')
  ```
  Used as the default customer everywhere.

## 7.3 `BillItem` — `models/bill_item.dart`

```dart
class BillItem {
  final String productId;
  final String productName;
  final String unit;
  double quantity;
  final double rate;           // sale price per unit
  double discountPercent;
  final double maxStock;       // available stock; 0 = unlimited fallback
}
```

- **Computed:**
  - `grossAmount` = `rate × quantity`
  - `discountAmount` = `grossAmount × discountPercent / 100`
  - `total` = `grossAmount − discountAmount`
  - GST stubs: `rateWithGst = rate`, `gstPercent = 0`, `gstAmount = 0`,
    `taxableAmount = total`.
- `BillItem.fromProduct(Product, {quantity})` — builds from a catalogue product.
- `BillItem.fromJson` / `toJson` — used for saving/loading bills.
- `copyWith({quantity, discountPercent})` — returns a mutated copy.

## 7.4 `Bill` — `models/bill.dart`

```dart
class Bill {
  final String billNumber;
  final String date;            // ISO-8601
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String paymentType;     // Cash | Credit | UPI
  final String salesType;       // Retail | Wholesale | Credit
  final String through;         // salesman / agent
  final String area;
  final String priceList;
  final String remarks;
  final List<BillItem> items;
  final double subtotal;
  final double gstTotal;        // always 0
  final double discountTotal;
  final double roundOff;        // always 0
  final double grandTotal;
  final Map<String, double> gstBreakup;  // empty
  final int itemCount;
}
```

- `Bill.fromJson` — parses the `/bills/` and `/bill/` API responses, including the
  `gst_breakup` map.
- `toJson` — full round-trip serialisation.

## 7.5 `InvoiceItem` / `Invoice` — `models/invoice_model.dart`

The **company invoice** data model used by the printable company invoice & the
consolidated invoice.

```dart
class InvoiceItem {
  final String description;
  final String hsn;
  final String unit;
  final double qty;
  final double rate;
  double get amount => qty * rate;
}
```

```dart
class Invoice {
  // Static company & bank details (VELA AGENCY)
  static const companyName = 'VELA AGENCY';
  static const companyAddress = 'Burgur Road, Vellai Pillaiyar Kovil, Anthiyur, Tamil Nadu.';
  static const companyGstin = '33BAZPM1155J1ZB';
  static const companyFssai = 'SAMPLE-FSSAI';
  static const companyPan = 'BAZM115J';
  static const companyPhone = '+91 986522355';
  static const companyEmail = 'velaagency27@gmail.com';
  static const bankName = 'HDFC Bank';
  static const accountNo = '50200120799532';
  static const ifsc = 'HDFC0004901';

  // Dynamic fields
  final String invoiceNo;
  final String invoiceDate;
  final String invoiceTime;
  final String customerName;
  final String customerAddress;
  final String customerGstin;
  final String customerPan;
  final String paymentMode;
  final String txnId;
  final String upiId;
  final List<InvoiceItem> items;
  double get totalAmount => items.fold(0, (s, i) => s + i.amount);
}
```

- `Invoice.fromJson` expects a nested shape: `{invoiceNo, invoiceDate, invoiceTime,
  customer:{name,address,gstin,pan}, payment:{mode,txnId,upiId}, items:[{description,
  hsn,unit,qty,rate}]}`.

## Related docs

- [05 — Backend Models](05_backend_models.md)
- [08 — Frontend State Provider](08_frontend_state_provider.md)
- [10 — Frontend Screens](10_frontend_screens.md)
