import 'package:intl/intl.dart';

String moneyMinor(int cents) =>
    'Rs. ${NumberFormat('#,##0.##').format(cents / 100)}';

/// Accept rupees with at most two decimal places, without float rounding.
int? parseMoneyMinor(String text) {
  final value = text.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null || whole > 90071992547409) return null;
  final fraction = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  final amount = whole * 100 + fraction;
  return amount <= 9007199254740991 ? amount : null;
}
