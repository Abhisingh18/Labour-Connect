import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _date = DateFormat('d MMM yyyy');
  static final _dateFull = DateFormat('EEE, d MMM yyyy');
  static final _month = DateFormat('MMM yyyy');
  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String date(DateTime d) => _date.format(d);
  static String dateFull(DateTime d) => _dateFull.format(d);

  static String monthLabel(String yyyymm) {
    try {
      final parts = yyyymm.split('-');
      return _month.format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
    } catch (_) {
      return yyyymm;
    }
  }

  static String money(num amount) => _currency.format(amount);

  static String time(String? hhmmss) {
    if (hhmmss == null || hhmmss.isEmpty) return '--';
    try {
      final parts = hhmmss.split(':');
      final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return hhmmss;
    }
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
