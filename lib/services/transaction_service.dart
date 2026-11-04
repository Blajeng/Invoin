import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Service untuk operasi CRUD dan query transaksi.
class TransactionService {
  final TransactionRepository _repository;

  TransactionService(this._repository);

  /// Ambil semua transaksi tersimpan, urut dari terbaru.
  List<Transaction> getAllTransactions() {
    return _repository.getAll();
  }

  /// Ambil satu transaksi berdasarkan ID.
  Transaction? getTransactionById(String id) {
    return _repository.getById(id);
  }

  /// Update transaksi yang sudah ada (PRD US-03).
  bool updateTransaction(Transaction transaction) {
    return _repository.update(transaction);
  }

  /// Hapus transaksi.
  bool deleteTransaction(String id) {
    return _repository.delete(id);
  }

  /// Ambil transaksi dalam rentang tanggal.
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _repository.getByDateRange(start, end);
  }

  /// Hitung total pengeluaran dari list transaksi.
  double calculateTotal(List<Transaction> transactions) {
    return _repository.calculateTotal(transactions);
  }

  /// Ambil transaksi bulan ini.
  List<Transaction> getCurrentMonthTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return _repository.getByDateRange(startOfMonth, endOfMonth);
  }

  /// Hitung total pengeluaran bulan ini.
  double getCurrentMonthTotal() {
    final transactions = getCurrentMonthTransactions();
    return calculateTotal(transactions);
  }
}
