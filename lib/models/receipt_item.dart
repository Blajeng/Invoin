/// Model untuk satu item dalam struk.
/// - name (required): Nama item
/// - quantity (required): Jumlah item (> 0)
/// - price (required): Harga satuan (>= 0)
class ReceiptItem {
  final String name;
  final int quantity;
  final double price;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  /// Total harga item ini (quantity × price)
  double get subtotal => quantity * price;

  /// Buat copy dengan field yang diubah
  ReceiptItem copyWith({
    String? name,
    int? quantity,
    double? price,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
