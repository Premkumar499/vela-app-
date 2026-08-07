// ============================================================
// NUMBER TO WORDS CONVERTER (Indian System)
// ============================================================

class NumberToWords {
  static const _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String _twoDigits(int n) {
    if (n < 20) return _ones[n];
    return '${_tens[n ~/ 10]}${n % 10 != 0 ? ' ${_ones[n % 10]}' : ''}';
  }

  static String _threeDigits(int n) {
    if (n >= 100) {
      return '${_ones[n ~/ 100]} Hundred${n % 100 != 0 ? ' and ${_twoDigits(n % 100)}' : ''}';
    }
    return _twoDigits(n);
  }

  static String convert(int number) {
    if (number == 0) return 'Zero';

    String result = '';
    final crore = number ~/ 10000000;
    number %= 10000000;

    final lakh = number ~/ 100000;
    number %= 100000;

    final thousand = number ~/ 1000;
    number %= 1000;

    final rest = number;

    if (crore > 0) result += '${_threeDigits(crore)} Crore ';
    if (lakh > 0) result += '${_threeDigits(lakh)} Lakh ';
    if (thousand > 0) result += '${_threeDigits(thousand)} Thousand ';
    if (rest > 0) result += _threeDigits(rest);

    return result.trim();
  }

  static String amountInWords(double amount) {
    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String words = '${convert(rupees)} Rupees';
    if (paise > 0) words += ' and ${convert(paise)} Paise';
    return '$words Only';
  }
}
