import '../models/transaction.dart';
class TransactionRepository {
  final List<Transaction> _transactions = [];

  /// Ambil semua transaksi, urut dari terbaru.
  List<Transaction> getAll() {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return sorted;
  }

  /// Ambil satu transaksi berdasarkan ID.
  /// Mengembalikan null jika tidak ditemukan.
  Transaction? getById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Simpan transaksi baru.
  void add(Transaction transaction) {
    _transactions.add(transaction);
  }

  /// Update transaksi yang sudah ada.
  /// Mengembalikan true jika berhasil, false jika ID tidak ditemukan.
  bool update(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index == -1) return false;
    _transactions[index] = transaction;
    return true;
  }

  /// Hapus transaksi berdasarkan ID.
  /// Mengembalikan true jika berhasil, false jika ID tidak ditemukan.
  bool delete(String id) {
    final lengthBefore = _transactions.length;
    _transactions.removeWhere((t) => t.id == id);
    return _transactions.length < lengthBefore;
  }

  /// Ambil transaksi dalam rentang tanggal tertentu.
  /// Berguna untuk AI Chat context (PRD §FR-08).
  List<Transaction> getByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) {
      return !t.transactionDate.isBefore(start) &&
          !t.transactionDate.isAfter(end);
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  /// Hitung total pengeluaran dari list transaksi.
  /// Perhitungan deterministik — dilakukan di app logic, bukan AI (PRD Principle 3).
  double calculateTotal(List<Transaction> transactions) {
    double sum = 0;
    for (final t in transactions) {
      sum += t.total;
    }
    return sum;
  }
}
