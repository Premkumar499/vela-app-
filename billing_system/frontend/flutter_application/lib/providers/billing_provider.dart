import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../models/bill_item.dart';
import '../utils/constants.dart';

/// Central state manager for the billing flow — no GST.
class BillingProvider with ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  Customer         _customer    = Customer.walkIn;
  String           _customerPhone = '';
  final List<BillItem> _items   = [];
  String _paymentType = AppConstants.paymentTypes.first;
  String _salesType   = AppConstants.salesTypes.first;
  String _priceList   = AppConstants.priceLists.first;
  String _through     = '';
  String _area        = '';
  String _remarks     = '';

  // ── Getters ───────────────────────────────────────────────────────────────
  Customer         get customer    => _customer;
  String           get customerPhone => _customerPhone;
  List<BillItem>   get items       => List.unmodifiable(_items);
  String           get paymentType => _paymentType;
  String           get salesType   => _salesType;
  String           get priceList   => _priceList;
  String           get through     => _through;
  String           get area        => _area;
  String           get remarks     => _remarks;
  int              get itemCount   => _items.length;

  // ── Computed totals (no GST) ──────────────────────────────────────────────
  double get subtotal      => _r(_items.fold(0.0, (s, i) => s + i.grossAmount));
  double get discountTotal => _r(_items.fold(0.0, (s, i) => s + i.discountAmount));
  double get gstTotal      => 0.0;   // no GST in this system
  double get roundOff      => 0.0;   // no rounding in this system
  double get grandTotal    => _r(_items.fold(0.0, (s, i) => s + i.total));

  /// GST breakup by slab — empty since no GST applies.
  Map<String, double> get gstBreakup => {};

  double _r(double v) => double.parse(v.toStringAsFixed(2));

  // ── Setters ───────────────────────────────────────────────────────────────
  void setCustomer(Customer c)    { _customer = c; _area = c.area; _customerPhone = c.phone; notifyListeners(); }
  void setCustomerPhone(String v) { _customerPhone = v; notifyListeners(); }
  void setPaymentType(String v)   { _paymentType = v; notifyListeners(); }
  void setSalesType(String v)     { _salesType   = v; notifyListeners(); }
  void setPriceList(String v)     { _priceList   = v; notifyListeners(); }
  void setThrough(String v)       { _through     = v; notifyListeners(); }
  void setArea(String v)          { _area        = v; notifyListeners(); }
  void setRemarks(String v)       { _remarks     = v; notifyListeners(); }

  // ── Item management ───────────────────────────────────────────────────────
  /// Returns false if the product is out of stock.
  bool addProduct(Product product, {double quantity = 1}) {
    if (product.stock <= 0) return false;   // no stock at all
    final idx = _items.indexWhere((i) => i.productId == product.id);
    if (idx != -1) {
      final current = _items[idx].quantity;
      final max     = _items[idx].maxStock;
      if (max > 0 && current >= max) return false;  // already at stock limit
      _items[idx].quantity = (current + quantity).clamp(0, max > 0 ? max : double.infinity);
    } else {
      _items.add(BillItem.fromProduct(product, quantity: quantity));
    }
    notifyListeners();
    return true;
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateQuantity(int index, double quantity) {
    if (index >= 0 && index < _items.length) {
      final max = _items[index].maxStock;
      _items[index].quantity = max > 0 ? quantity.clamp(1, max) : quantity;
      notifyListeners();
    }
  }

  void updateDiscount(int index, double discountPercent) {
    if (index >= 0 && index < _items.length) {
      _items[index].discountPercent = discountPercent;
      notifyListeners();
    }
  }

  void clearItems() { _items.clear(); notifyListeners(); }

  void resetBill() {
    _items.clear();
    _customer    = Customer.walkIn;
    _customerPhone = '';
    _paymentType = AppConstants.paymentTypes.first;
    _salesType   = AppConstants.salesTypes.first;
    _priceList   = AppConstants.priceLists.first;
    _through     = '';
    _area        = '';
    _remarks     = '';
    notifyListeners();
  }

  bool get canSave => _items.isNotEmpty && _customer.id != '00000000-0000-0000-0000-000000000000';
}
