import 'package:flutter/material.dart';

/// Thermal-style receipt widget.
///
/// Dynamic fields (from JSON):
///   company.name, company.address
///   invoice.bill_no, invoice.date, invoice.time, invoice.invoice_type
///   customer.name
///   items[].product_name, brand, qty, unit, rate, discount, amount
///   summary.total_qty, summary.total
///   payment.method
///
/// Everything else (Tamil text, logo, footer) is static.
class ReceiptWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReceiptWidget({super.key, required this.data});

  Map<String, dynamic> get _company  => (data['company']  as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _invoice  => (data['invoice']  as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _customer => (data['customer'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _summary  => (data['summary']  as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _payment  => (data['payment']  as Map<String, dynamic>?) ?? {};
  List<dynamic>        get _items    => (data['items']    as List<dynamic>?)         ?? [];

  @override
  Widget build(BuildContext context) {
    // Use CustomPaint for the saw-tooth border — works with any height
    return CustomPaint(
      painter: _SawToothPainter(),
      child: Container(
        width: 380,
        color: const Color(0xFFF4F6F8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _divider('-'),
            const SizedBox(height: 10),
            const Center(
              child: Text('BILL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            _buildBillDetails(),
            const SizedBox(height: 10),
            _divider('-'),
            const SizedBox(height: 8),
            _buildTableHeader(),
            const SizedBox(height: 8),
            _divider('-'),
            const SizedBox(height: 8),
            _buildItemsList(),
            const SizedBox(height: 8),
            _divider('-'),
            const SizedBox(height: 12),
            _buildSummary(),
            const SizedBox(height: 12),
            _divider('='),
            const SizedBox(height: 12),
            _buildTotal(),
            const SizedBox(height: 12),
            _divider('='),
            const SizedBox(height: 12),
            _divider('-'),
            const SizedBox(height: 12),
            Text(
              'Payment Mode : ${(_payment['method'] ?? 'CASH').toString().toUpperCase()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _divider('-'),
            const SizedBox(height: 24),
            const Center(
              child: Text('THANK YOU! VISIT AGAIN!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name    = _company['name']    as String? ?? 'VELA AGENCY';
    final address = _company['address'] as String? ?? 'Anthiyur';

    return Column(
      children: [
        Icon(Icons.energy_savings_leaf, color: Colors.green[800], size: 54),
        const SizedBox(height: 10),
        const Text('வேலா ஏஜென்சி',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Roboto')),
        const SizedBox(height: 6),
        const Text(
          'மளிகை மொத்த மற்றும் சில்லறை\nவியாபாரம்...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Roboto', height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          'பர்கூர் ரோடு, வெள்ளை பிள்ளையார் கோவில், $address.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.black87, fontFamily: 'Roboto', height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBillDetails() {
    final billNo = _invoice['bill_no']       as String? ?? '-';
    final date   = _invoice['date']          as String? ?? '-';
    final time   = _invoice['time']          as String? ?? '-';
    final type   = _invoice['invoice_type']  as String? ?? 'NON_GST';
    final cust   = _customer['name']         as String? ?? 'Walk-in Customer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_kv('Bill No', billNo), _kv('Date', date, align: TextAlign.right)],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_kv('Time', time), _kv('Type', type, align: TextAlign.right)],
        ),
        const SizedBox(height: 4),
        _kv('Customer', cust),
      ],
    );
  }

  Widget _kv(String label, String value, {TextAlign align = TextAlign.left}) => Text(
        '$label : $value',
        textAlign: align,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(flex: 1, child: _stackedHeader('வ.எண்',  'S.No',   CrossAxisAlignment.start)),
        Expanded(flex: 4, child: _stackedHeader('விவரம்',  'Item',   CrossAxisAlignment.start)),
        Expanded(flex: 1, child: _stackedHeader('அளவு',   'Qty',    CrossAxisAlignment.end)),
        Expanded(flex: 2, child: _stackedHeader('விலை',   'Rate',   CrossAxisAlignment.end)),
        Expanded(flex: 2, child: _stackedHeader('தொகை',  'Amount', CrossAxisAlignment.end)),
      ],
    );
  }

  Widget _stackedHeader(String ta, String en, CrossAxisAlignment align) => Column(
        crossAxisAlignment: align,
        children: [
          Text(ta, style: const TextStyle(fontSize: 9,  fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
          Text(en, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildItemsList() {
    return Column(
      children: List.generate(_items.length, (i) {
        final item     = _items[i] as Map<String, dynamic>;
        final name     = item['product_name'] as String? ?? '';
        final brand    = item['brand']        as String? ?? '';
        final qty      = item['qty'];
        final unit     = item['unit']         as String? ?? '';
        final rate     = item['rate'];
        final discount = item['discount'];
        final amount   = item['amount'];
        final isLast   = i == _items.length - 1;

        final desc     = brand.isNotEmpty ? '$name ($brand)' : name;
        final discStr  = (discount != null && discount != 0) ? ' [-$discount]' : '';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 11))),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        if (unit.isNotEmpty)
                          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        if (discStr.isNotEmpty)
                          Text('Disc$discStr',
                              style: const TextStyle(fontSize: 10, color: Colors.red)),
                      ],
                    ),
                  ),
                  Expanded(flex: 1,
                      child: Text('$qty',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2,
                      child: Text('₹$rate',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2,
                      child: Text('₹$amount',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            if (!isLast) _divider('·', spacing: 2.0, color: Colors.grey.shade400),
          ],
        );
      }),
    );
  }

  Widget _buildSummary() {
    final totalQty = _summary['total_qty'] ?? 0;
    return Text('Total Qty : $totalQty',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
  }

  Widget _buildTotal() {
    final total = _summary['total'] ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('TOTAL AMOUNT',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        Text('₹ $total',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _divider(String char, {double spacing = 1.0, Color color = Colors.black87}) => Text(
        char * 100,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: TextStyle(fontSize: 12, letterSpacing: spacing, color: color, fontWeight: FontWeight.w600),
      );
}

// ── Saw-tooth border painter (works with any height) ──────────────────────────
class _SawToothPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tw = 8.0;
    const th = 5.0;
    final paint = Paint()
      ..color = const Color(0xFFF4F6F8)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Top saw-tooth
    path.moveTo(0, th);
    for (double x = 0; x < size.width; x += tw) {
      path.lineTo(x + tw / 2, 0);
      path.lineTo(x + tw, th);
    }
    // Right straight edge
    path.lineTo(size.width, size.height - th);
    // Bottom saw-tooth
    for (double x = size.width; x > 0; x -= tw) {
      path.lineTo(x - tw / 2, size.height);
      path.lineTo(x - tw, size.height - th);
    }
    path.lineTo(0, th);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

