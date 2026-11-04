import 'receipt_item.dart';

/// Model transaksi utama.
///
/// Sesuai PRD §9 — Transaction:
/// - id, storeName, transactionDate, total, createdAt, updatedAt → required
/// - category, items, receiptImagePath → optional
///
/// Penting (PRD §9 Important Data Rule):
/// AI output ≠ final transaction. Model ini digunakan baik untuk draft
/// maupun transaksi final. Perbedaannya: draft belum disimpan ke storage.
class Transaction {
  final String id;
  final String storeName;
  final DateTime transactionDate;
  final double total;
  final String? category;
  final List<ReceiptItem> items;
  final String? receiptImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.storeName,
    required this.transactionDate,
    required this.total,
    this.category,
    this.items = const [],
    this.receiptImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Buat copy dengan field yang diubah.
  /// Berguna untuk edit transaction dan update draft.
  Transaction copyWith({
    String? id,
    String? storeName,
    DateTime? transactionDate,
    double? total,
    String? category,
    List<ReceiptItem>? items,
    String? receiptImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      transactionDate: transactionDate ?? this.transactionDate,
      total: total ?? this.total,
      category: category ?? this.category,
      items: items ?? this.items,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
