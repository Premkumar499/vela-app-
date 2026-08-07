import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../providers/billing_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/pos_theme.dart';
import '../widgets/pos_bill_item_row.dart';
import '../widgets/pos_payment_selector.dart';
import '../widgets/pos_product_card.dart';
import '../widgets/pos_summary_section.dart';
import '../widgets/bilingual_bill_dashboard.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PosBillingScreen extends StatefulWidget {
  const PosBillingScreen({super.key});

  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  // ── Product state ────────────────────────────────────────────────────────
  List<Product> _allProducts    = [];
  List<Product> _filtered       = [];
  List<String>  _categories     = ['All'];
  String        _selectedCat    = 'All';
  bool          _loadingProds   = true;

  // ── Search ───────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── Bill state ───────────────────────────────────────────────────────────
  bool _isSaving = false;
  String _invoiceNum = 'DRAFT';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadProducts() async {
    setState(() => _loadingProds = true);
    final result = await ApiService.getProducts();
    if (!mounted) return;
    if (result.success && result.data != null) {
      _allProducts = result.data!;
      _filtered    = _allProducts;
      final cats   = _allProducts.map((p) => p.category)
          .where((c) => c != 'Function Bill Products')
          .toSet().toList()..sort();
      _categories  = ['All', ...cats];
    }
    setState(() => _loadingProds = false);
  }

  void _applyFilter() {
    final q   = _searchCtrl.text.trim().toLowerCase();
    final cat = _selectedCat;
    setState(() {
      _filtered = _allProducts.where((p) {
        if (p.category == 'Function Bill Products') return false;
        final matchCat  = cat == 'All' || p.category == cat;
        final matchText = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
        return matchCat && matchText;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCat = cat);
    _applyFilter();
  }

  // ─── Bill actions ──────────────────────────────────────────────────────────
  Future<void> _saveBill() async {
    final prov = context.read<BillingProvider>();
    if (!prov.canSave) {
      _snack('Add at least one item to save.', error: true);
      return;
    }
    setState(() => _isSaving = true);
    final result = await ApiService.saveBill(
      customer:    prov.customer,
      items:       prov.items,
      paymentType: prov.paymentType,
      customerPhone: prov.customerPhone,
      salesType:   prov.salesType,
      remarks:     prov.remarks,
      through:     prov.through,
      area:        prov.area,
      priceList:   prov.priceList,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      final billNum = result.data?['bill_number'] as String? ?? 'SAVED';
      setState(() => _invoiceNum = billNum);

      // Build receipt JSON from current bill state
      final now = DateTime.now();
      final receiptData = {
        'company': {
          'name':    'VELA AGENCY',
          'address': 'Anthiyur',
        },
        'invoice': {
          'bill_no':      billNum,
          'invoice_type': 'NON_GST',
          'date': '${now.day.toString().padLeft(2,'0')}/'
                  '${now.month.toString().padLeft(2,'0')}/'
                  '${now.year}',
          'time': _formatTime(now),
        },
        'customer': {
          'name': prov.customer.name,
        },
        'items': prov.items.map((item) => {
          'product_name': item.productName,
          'brand':        '',
          'qty':          item.quantity % 1 == 0
                            ? item.quantity.toInt()
                            : item.quantity,
          'unit':         item.unit,
          'rate':         item.rate.toStringAsFixed(2),
          'discount':     item.discountPercent > 0
                            ? item.discountPercent.toStringAsFixed(0)
                            : 0,
          'amount':       item.total.toStringAsFixed(2),
        }).toList(),
        'summary': {
          'total_qty': prov.items.fold<num>(
              0, (s, i) => s + (i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity)),
          'total':     prov.grandTotal.toStringAsFixed(2),
        },
        'payment': {
          'method': prov.paymentType,
        },
      };

      // Show bilingual bill dashboard
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => Dialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
                child: BilingualBillDashboard(
                  receiptData: receiptData,
                  onClose: () {
                    Navigator.of(dialogCtx).pop();
                    prov.resetBill();
                    setState(() => _invoiceNum = 'DRAFT');
                  },
                ),
              ),
            ),
          ),
        );
      }
    } else {
      _snack(result.error ?? 'Failed to save bill.', error: true);
    }
  }

  String _formatTime(DateTime dt) {
    final h   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m   = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  void _cancelBill() {
    final prov = context.read<BillingProvider>();
    if (prov.itemCount == 0) return;
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Cancel Bill',
        message: 'Clear all items and cancel this bill?',
        danger:  true,
        onConfirm: () {
          prov.resetBill();
          setState(() => _invoiceNum = 'DRAFT');
        },
      ),
    );
  }

  void _newBill() {
    final prov = context.read<BillingProvider>();
    if (prov.itemCount == 0) return;
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'New Bill',
        message: 'Discard current bill and start a new one?',
        onConfirm: () {
          prov.resetBill();
          setState(() => _invoiceNum = 'DRAFT');
        },
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? PosTheme.danger : PosTheme.success,
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillingProvider>();

    return Scaffold(
      backgroundColor: PosTheme.background,
      // ── App bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: PosTheme.primary,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(PosTheme.radiusSm),
            ),
            child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ERP Billing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('New Bill · ${provider.customer.name}',
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          // New bill
          TextButton.icon(
            onPressed: _newBill,
            icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white70),
            label: const Text('New Bill',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(width: 4),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ── Body: side-by-side ───────────────────────────────────────────────
      body: Row(
        children: [
          // ── LEFT PANEL (65%) ────────────────────────────────────────────
          Expanded(
            flex: 65,
            child: _LeftPanel(
              categories:   _categories,
              selectedCat:  _selectedCat,
              products:     _filtered,
              loading:      _loadingProds,
              searchCtrl:   _searchCtrl,
              searchFocus:  _searchFocus,
              onCategory:   _selectCategory,
              onProduct:    (p) => provider.addProduct(p),
            ),
          ),
          // ── RIGHT PANEL (35%) ───────────────────────────────────────────
          Expanded(
            flex: 35,
            child: _RightPanel(
              provider:   provider,
              invoiceNum: _invoiceNum,
              isSaving:   _isSaving,
              onSave:     _saveBill,
              onCancel:   _cancelBill,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  final List<String>  categories;
  final String        selectedCat;
  final List<Product> products;
  final bool          loading;
  final TextEditingController searchCtrl;
  final FocusNode             searchFocus;
  final ValueChanged<String>  onCategory;
  final ValueChanged<Product> onProduct;

  const _LeftPanel({
    required this.categories,
    required this.selectedCat,
    required this.products,
    required this.loading,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onCategory,
    required this.onProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar + filter row ────────────────────────────────────
        Container(
          color: PosTheme.surface,
          padding: const EdgeInsets.fromLTRB(
            PosTheme.padLg, PosTheme.padMd,
            PosTheme.padLg, 0,
          ),
          child: _SearchBar(controller: searchCtrl, focusNode: searchFocus),
        ),
        // ── Category chips removed ────────────────────────────────────
        const Divider(height: 1, color: PosTheme.border),
        // ── Product grid ───────────────────────────────────────────────
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
                  ? _EmptyProducts(hasSearch: searchCtrl.text.isNotEmpty)
                  : _ProductGrid(products: products, onTap: onProduct),
        ),
      ],
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SearchBar({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:  controller,
      focusNode:   focusNode,
      autofocus:   false,
      style:       PosTheme.body,
      decoration: InputDecoration(
        hintText:    'Search Products...',
        prefixIcon:  const Icon(Icons.search_rounded, color: PosTheme.textHint, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: PosTheme.textHint),
                  onPressed: controller.clear,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ─── Category chips ────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<String>         categories;
  final String               selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat    = categories[i];
          final active = cat == selected;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            child: ChoiceChip(
              label: Text(cat),
              selected: active,
              onSelected: (_) => onSelected(cat),
              selectedColor: PosTheme.primary,
              backgroundColor: PosTheme.surface,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : PosTheme.textSecondary,
              ),
              side: BorderSide(
                color: active ? PosTheme.primary : PosTheme.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }
}

// ─── Product grid ──────────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  final List<Product>         products;
  final ValueChanged<Product> onTap;

  const _ProductGrid({required this.products, required this.onTap});

  // Each card is exactly this tall — hard pixel cap, no aspect ratio math.
  static const double _cardH = 80.0;
  static const double _gap   = 8.0;
  static const double _pad   = 12.0;

  @override
  Widget build(BuildContext context) {
    final availW = MediaQuery.of(context).size.width * 0.65 - _pad * 2;
    final cols   = availW < 380 ? 1 : availW < 580 ? 2 : availW < 820 ? 3 : 4;
    final colW   = (availW - _gap * (cols - 1)) / cols;

    // Build rows of [cols] items each
    final rows = <List<Product>>[];
    for (var i = 0; i < products.length; i += cols) {
      rows.add(products.sublist(i, (i + cols).clamp(0, products.length)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(_pad),
      itemCount: rows.length,
      itemBuilder: (_, rowIdx) {
        final row = rows[rowIdx];
        return Padding(
          padding: EdgeInsets.only(bottom: rowIdx < rows.length - 1 ? _gap : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var ci = 0; ci < cols; ci++) ...[
                if (ci < row.length)
                  SizedBox(
                    width: colW,
                    height: _cardH,
                    child: PosProductCard(
                      product: row[ci],
                      onTap:   () => onTap(row[ci]),
                    ),
                  )
                else
                  SizedBox(width: colW, height: _cardH), // empty filler
                if (ci < cols - 1) const SizedBox(width: _gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final bool hasSearch;
  const _EmptyProducts({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size: 64, color: PosTheme.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No products match your search' : 'No products available',
            style: PosTheme.bodyBold.copyWith(color: PosTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _RightPanel extends StatelessWidget {
  final BillingProvider provider;
  final String invoiceNum;
  final bool   isSaving;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  const _RightPanel({
    required this.provider,
    required this.invoiceNum,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PosTheme.rightPanel,
      child: Column(
        children: [
          // ── Bill header ─────────────────────────────────────────────
          _BillHeader(
            invoiceNum:  invoiceNum,
            customerName: provider.customer.name,
            itemCount:   provider.itemCount,
            paymentType: provider.paymentType,
          ),
          // ── Customer details input ─────────────────────────────────
          _CustomerDetailsInput(provider: provider),
          // ── Column labels ──────────────────────────────────────────
          _BillTableHeader(),
          // ── Bill items list ────────────────────────────────────────
          Expanded(
            child: provider.items.isEmpty
                ? const PosEmptyCartPlaceholder()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: provider.items.length,
                    itemBuilder: (_, i) {
                      final item = provider.items[i];
                      return PosBillItemRow(
                        index:      i,
                        item:       item,
                        onIncrease: () => provider.updateQuantity(i, item.quantity + 1),
                        onDecrease: () {
                          if (item.quantity > 1) {
                            provider.updateQuantity(i, item.quantity - 1);
                          } else {
                            provider.removeItem(i);
                          }
                        },
                        onDelete:   () => provider.removeItem(i),
                      );
                    },
                  ),
          ),
          // ── Summary ────────────────────────────────────────────────
          PosSummarySection(
            subtotal:      provider.subtotal,
            discountTotal: provider.discountTotal,
            grandTotal:    provider.grandTotal,
          ),
          // ── Payment selector ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              top: PosTheme.padSm,
              bottom: PosTheme.padSm,
            ),
            child: PosPaymentSelector(
              selected:  provider.paymentType,
              onChanged: provider.setPaymentType,
            ),
          ),
          // ── Action buttons ─────────────────────────────────────────
          _ActionButtons(
            isSaving:  isSaving,
            canSave:   provider.canSave,
            onComplete: onSave,
            onCancel:  onCancel,
          ),
        ],
      ),
    );
  }
}

// ─── Bill header ──────────────────────────────────────────────────────────────
class _BillHeader extends StatelessWidget {
  final String invoiceNum;
  final String customerName;
  final int    itemCount;
  final String paymentType;

  const _BillHeader({
    required this.invoiceNum,
    required this.customerName,
    required this.itemCount,
    required this.paymentType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PosTheme.padLg,
        vertical: PosTheme.padMd,
      ),
      decoration: const BoxDecoration(
        color: PosTheme.primarySoft,
        border: Border(bottom: BorderSide(color: PosTheme.border)),
      ),
      child: Row(
        children: [
          // Invoice icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: PosTheme.primary,
              borderRadius: BorderRadius.circular(PosTheme.radiusSm),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoiceNum,
                  style: PosTheme.bodyBold.copyWith(
                    color: PosTheme.primary, fontSize: 15,
                  ),
                ),
                Text(
                  customerName,
                  style: PosTheme.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Item count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: itemCount > 0 ? PosTheme.primary : PosTheme.border,
              borderRadius: BorderRadius.circular(PosTheme.radiusXl),
            ),
            child: Text(
              '$itemCount items',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bill table header ────────────────────────────────────────────────────────
class _BillTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PosTheme.padMd, vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4FF),
        border: Border(bottom: BorderSide(color: PosTheme.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22 + 8), // row num spacer
          Expanded(
            flex: 4,
            child: Text('ITEM',
                style: PosTheme.caption.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          Expanded(
            flex: 3,
            child: Text('QTY',
                textAlign: TextAlign.center,
                style: PosTheme.caption.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          Expanded(
            flex: 2,
            child: Text('RATE',
                textAlign: TextAlign.right,
                style: PosTheme.caption.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          Expanded(
            flex: 2,
            child: Text('AMT',
                textAlign: TextAlign.right,
                style: PosTheme.caption.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(width: 36), // delete btn spacer
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final bool isSaving;
  final bool canSave;
  final Future<void> Function() onComplete;
  final VoidCallback onCancel;

  const _ActionButtons({
    required this.isSaving,
    required this.canSave,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PosTheme.padMd),
      decoration: const BoxDecoration(
        color: PosTheme.surface,
        border: Border(top: BorderSide(color: PosTheme.border)),
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: canSave ? onCancel : null,
              style: PosTheme.dangerButton(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 8),
          // Complete only
          Expanded(
            flex: 4,
            child: ElevatedButton.icon(
              onPressed: canSave && !isSaving ? onComplete : null,
              style: PosTheme.successButton(),
              icon: isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(isSaving ? 'Saving…' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Details Input ───────────────────────────────────────────────────
class _CustomerDetailsInput extends StatelessWidget {
  final BillingProvider provider;

  const _CustomerDetailsInput({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PosTheme.padMd),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: PosTheme.border)),
      ),
      child: Row(
        children: [
          // Customer Name Input
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PosTheme.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                final currentCustomer = provider.customer;
                provider.setCustomer(Customer(
                  id: currentCustomer.id,
                  name: value.isEmpty ? 'Walk-in Customer' : value,
                  phone: provider.customerPhone,
                  address: currentCustomer.address,
                  area: currentCustomer.area,
                  gstin: currentCustomer.gstin,
                  creditLimit: currentCustomer.creditLimit,
                  balance: currentCustomer.balance,
                ));
              },
            ),
          ),
          const SizedBox(width: 12),
          // Phone Input
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PosTheme.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                provider.setCustomerPhone(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool danger;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PosTheme.radiusLg)),
      title: Text(title, style: PosTheme.subtitle),
      content: Text(message, style: PosTheme.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: danger
              ? ElevatedButton.styleFrom(backgroundColor: PosTheme.danger)
              : PosTheme.primaryButton(height: 40),
          child: Text(danger ? 'Yes, Cancel' : 'Confirm'),
        ),
      ],
    );
  }
}
