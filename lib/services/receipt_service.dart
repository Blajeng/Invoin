import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/receipt_item.dart';
import '../repositories/transaction_repository.dart';

/// Service untuk orchestrate receipt flow.
/// image → AI analyze → structured result → draft → validate → save

class ReceiptService {
  final TransactionRepository _repository;
  final _uuid = const Uuid();

  ReceiptService(this._repository);
  Future<Transaction> analyzeReceipt(String imagePath) async {
    // Simulasi delay jaringan AI
    await Future.delayed(const Duration(seconds: 2));

    final now = DateTime.now();
    return Transaction(
      id: _uuid.v4(),
      storeName: 'Toko Contoh',
      transactionDate: now,
      total: 85000,
      category: 'Makanan & Minuman',
      items: const [
        ReceiptItem(name: 'Nasi Goreng', quantity: 2, price: 25000),
        ReceiptItem(name: 'Es Teh Manis', quantity: 2, price: 8000),
        ReceiptItem(name: 'Kerupuk', quantity: 1, price: 5000),
        ReceiptItem(name: 'Tahu Goreng', quantity: 2, price: 7000),
      ],
      receiptImagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Simpan transaksi yang sudah dikonfirmasi user.
  /// Transaksi hanya disimpan setelah user melakukan confirmation.
  void saveTransaction(Transaction transaction) {
    _repository.add(transaction);
  }
}
