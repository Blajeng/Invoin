import 'package:intl/intl.dart';

/// Format angka ke format Rupiah.
/// Contoh: 350000 → "Rp 350.000"
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format DateTime ke string tanggal yang mudah dibaca.
/// Contoh: 2026-09-25 → "25 Sep 2026"
String formatDate(DateTime date) {
  final formatter = DateFormat('dd MMM yyyy', 'id_ID');
  return formatter.format(date);
}

/// Format DateTime ke string tanggal lengkap.
/// Contoh: 2026-09-25 → "Kamis, 25 September 2026"
String formatDateFull(DateTime date) {
  final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  return formatter.format(date);
}

/// Format DateTime ke string untuk input field.
/// Contoh: 2026-09-25 → "2026-09-25"
String formatDateForInput(DateTime date) {
  final formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}
