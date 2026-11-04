import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/receipt_item.dart';
import '../services/receipt_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

/// Transaction Review Screen
/// Menampilkan draft hasil AI dan menyediakan editing sebelum confirmation.
class TransactionReviewScreen extends StatefulWidget {
  final ReceiptService receiptService;

  const TransactionReviewScreen({
    super.key,
    required this.receiptService,
  });

  @override
  State<TransactionReviewScreen> createState() =>
      _TransactionReviewScreenState();
}

class _TransactionReviewScreenState extends State<TransactionReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _storeNameController;
  late TextEditingController _totalController;
  late DateTime _selectedDate;
  late List<ReceiptItem> _items;

  // Controller per line item (Slice 4).
  //
  // Jumlah item tidak berubah pada slice ini (tidak ada tambah/hapus item),
  // sehingga daftar controller ini dibuat sekali saat draft dimuat dan
  // ukurannya tetap sama dengan `_items`.
  final List<TextEditingController> _itemNameControllers = [];
  final List<TextEditingController> _itemQuantityControllers = [];
  final List<TextEditingController> _itemPriceControllers = [];

  Transaction? _draft;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draft == null) {
      _draft = ModalRoute.of(context)?.settings.arguments as Transaction?;
      if (_draft != null) {
        _storeNameController =
            TextEditingController(text: _draft!.storeName);
        _totalController =
            TextEditingController(text: _draft!.total.toStringAsFixed(0));
        _selectedDate = _draft!.transactionDate;
        _items = List<ReceiptItem>.from(_draft!.items);

        for (final item in _items) {
          _itemNameControllers.add(TextEditingController(text: item.name));
          _itemQuantityControllers
              .add(TextEditingController(text: item.quantity.toString()));
          _itemPriceControllers
              .add(TextEditingController(text: _priceInputText(item.price)));
        }
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _totalController.dispose();
    for (final controller in _itemNameControllers) {
      controller.dispose();
    }
    for (final controller in _itemQuantityControllers) {
      controller.dispose();
    }
    for (final controller in _itemPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Teks awal untuk field harga.
  ///
  /// Angka bulat ditulis tanpa desimal, mengikuti konvensi field Total.
  /// Harga berdesimal ditulis apa adanya supaya nilai draft tidak berubah
  /// hanya karena user membuka form tanpa menyentuh field tersebut.
  String _priceInputText(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toString();
  }

  /// Perbarui satu line item di draft lokal.
  ///
  /// Hanya menyentuh draft lokal — tidak menulis ke repository
  /// (PRD §9 Important Data Rule: AI draft ≠ final transaction).
  ///
  /// Parameter yang `null` berarti "tidak diubah", mengikuti
  /// perilaku `ReceiptItem.copyWith`.
  ///
  /// Catatan (keputusan produk Slice 4 — Option A): perubahan line item
  /// TIDAK mengubah `Transaction.total`. Total tetap field independen
  /// yang diedit sendiri oleh user.
  void _updateItem(
    int index, {
    String? name,
    int? quantity,
    double? price,
  }) {
    setState(() {
      _items[index] = _items[index].copyWith(
        name: name,
        quantity: quantity,
        price: price,
      );
    });
  }

  /// Bangun satu blok line item yang bisa diedit.
  ///
  /// Field yang bisa diedit mengikuti model ReceiptItem:
  /// name, quantity, price (PRD §15: quantity/price valid jika item ada).
  Widget _buildEditableItem(int index) {
    final decoration = _inputDecoration('').copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('item_name_$index'),
            controller: _itemNameControllers[index],
            decoration: decoration.copyWith(hintText: 'Nama item'),
            onChanged: (value) => _updateItem(index, name: value),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('item_quantity_$index'),
                  controller: _itemQuantityControllers[index],
                  validator: validateQuantity,
                  keyboardType: TextInputType.number,
                  decoration: decoration.copyWith(labelText: 'Jumlah'),
                  // Nilai yang tidak bisa di-parse tidak dimasukkan ke draft,
                  // tetapi tetap dicegat oleh validateQuantity saat submit.
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim());
                    if (parsed != null) {
                      _updateItem(index, quantity: parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey('item_price_$index'),
                  controller: _itemPriceControllers[index],
                  validator: validatePrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: decoration.copyWith(
                    labelText: 'Harga',
                    prefixText: 'Rp ',
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.trim());
                    if (parsed != null) {
                      _updateItem(index, price: parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatCurrency(_items[index].subtotal),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryDarkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final confirmed = _draft!.copyWith(
      storeName: _storeNameController.text.trim(),
      transactionDate: _selectedDate,
      total: double.parse(_totalController.text),
      items: _items,
      updatedAt: DateTime.now(),
    );

    // Simpan (PRD: user melakukan explicit confirmation)
    widget.receiptService.saveTransaction(confirmed);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Kembalikan ID transaksi yang benar-benar baru disimpan, bukan `true`.
      //
      // Slice 6: pemanggil memakai ID ini untuk membuka Transaction Detail dari
      // transaksi yang tepat. Mengembalikan ID (bukan hanya penanda berhasil)
      // membuat jaminan "detail menampilkan transaksi yang baru disimpan"
      // benar secara konstruksi, bukan bergantung pada asumsi lain.
      //
      // `Batal` tetap mengembalikan `false` (lihat tombol Batal di bawah),
      // jadi kedua hasil ini tidak tertukar.
      Navigator.pop(context, confirmed.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Transaksi')),
        body: const Center(child: Text('Data draft tidak tersedia.')),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Review Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: accentColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Periksa dan koreksi data berikut sebelum menyimpan.',
                        style: TextStyle(fontSize: 13, color: textPrimaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Nama Toko',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _storeNameController,
                validator: validateStoreName,
                decoration: _inputDecoration('Masukkan nama toko'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Tanggal Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Icon(Icons.calendar_today,
                          size: 18, color: textSecondaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _totalController,
                validator: validateTotal,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Masukkan total').copyWith(
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${_items.length} item',
                    style:
                        const TextStyle(fontSize: 13, color: textSecondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Tidak ada item terdeteksi.',
                    style: TextStyle(color: textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...List.generate(
                  _items.length,
                  (index) => _buildEditableItem(index),
                ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondaryColor,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTransaction,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Konfirmasi & Simpan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textSecondaryColor.withValues(alpha: 0.5)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
