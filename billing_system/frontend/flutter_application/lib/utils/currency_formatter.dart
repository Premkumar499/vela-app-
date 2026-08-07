// ============================================================
// INDIAN CURRENCY FORMATTER (₹1,23,456.00)
// ============================================================

String formatCurrency(double value) {
  final isNegative = value < 0;
  value = value.abs();

  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  String intPart = parts[0];
  final decPart = parts[1];

  String result;
  if (intPart.length <= 3) {
    result = intPart;
  } else {
    String last3 = intPart.substring(intPart.length - 3);
    String remaining = intPart.substring(0, intPart.length - 3);
    final buffer = StringBuffer();
    while (remaining.length > 2) {
      buffer.write(',${remaining.substring(remaining.length - 2)}');
      remaining = remaining.substring(0, remaining.length - 2);
    }
    result = '$remaining$buffer,$last3';
  }

  return '${isNegative ? '-' : ''}₹$result.$decPart';
}
