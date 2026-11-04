import 'dart:io';

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

/// Transaction Detail / Edit Screen :
/// - Menampilkan detail transaksi
/// - Memungkinkan perubahan field yang diizinkan
/// - Menyimpan perubahan
/// - Riwayat menampilkan data terbaru
class TransactionDetailScreen extends StatefulWidget {
  final TransactionService transactionService;

  const TransactionDetailScreen({
    super.key,
    required this.transactionService,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  Transaction? _transaction;
  bool _isEditing = false;
  bool _isLoaded = false;

  late TextEditingController _storeNameController;
  late TextEditingController _totalController;
  late DateTime _selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      final transactionId =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (transactionId != null) {
        _transaction =
            widget.transactionService.getTransactionById(transactionId);
      }
      if (_transaction != null) {
        _storeNameController =
            TextEditingController(text: _transaction!.storeName);
        _totalController =
            TextEditingController(text: _transaction!.total.toStringAsFixed(0));
        _selectedDate = _transaction!.transactionDate;
      }
      _isLoaded = true;
    }
  }

  @override
  void dispose() {
    if (_transaction != null) {
      _storeNameController.dispose();
      _totalController.dispose();
    }
    super.dispose();
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
      setState(() => _selectedDate = picked);
    }
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final updated = _transaction!.copyWith(
      storeName: _storeNameController.text.trim(),
      transactionDate: _selectedDate,
      total: double.parse(_totalController.text),
      updatedAt: DateTime.now(),
    );

    final success = widget.transactionService.updateTransaction(updated);

    // "Save failure": kegagalan penyimpanan harus punya
    // state yang jelas, tidak diam saja.
    // `updateTransaction`  mengembalikan false kalau ID-nya tidak ada di repository, sehingga user tidak pernah
    // mendapat kabar apa-apa jika itu terjadi.
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan perubahan. Silakan coba lagi.'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _transaction = updated;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi berhasil diperbarui!'),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content:
            const Text('Transaksi yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              widget.transactionService.deleteTransaction(_transaction!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaksi dihapus.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: Text('Transaksi tidak ditemukan.')),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _toggleEdit,
              tooltip: 'Edit',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: errorColor),
            onPressed: _deleteTransaction,
            tooltip: 'Hapus',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nama Toko'),
              const SizedBox(height: 6),
              _isEditing
                  ? TextFormField(
                      controller: _storeNameController,
                      validator: validateStoreName,
                      decoration: _inputDecoration('Nama toko'),
                    )
                  : _buildValueText(_transaction!.storeName),
              const SizedBox(height: 16),

              _buildLabel('Tanggal'),
              const SizedBox(height: 6),
              _isEditing
                  ? InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatDate(_selectedDate),
                                style: const TextStyle(fontSize: 15)),
                            const Icon(Icons.calendar_today,
                                size: 18, color: textSecondaryColor),
                          ],
                        ),
                      ),
                    )
                  : _buildValueText(
                      formatDateFull(_transaction!.transactionDate)),
              const SizedBox(height: 16),

              _buildLabel('Total'),
              const SizedBox(height: 6),
              _isEditing
                  ? TextFormField(
                      controller: _totalController,
                      validator: validateTotal,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Total').copyWith(
                        prefixText: 'Rp ',
                      ),
                    )
                  : _buildValueText(
                      formatCurrency(_transaction!.total),
                      isBold: true,
                      color: primaryDarkColor,
                    ),
              const SizedBox(height: 24),

              if (_transaction!.items.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Item'),
                    Text(
                      '${_transaction!.items.length} item',
                      style: const TextStyle(
                          fontSize: 13, color: textSecondaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._transaction!.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity}x  ×  ${formatCurrency(item.price)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryDarkColor,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              if (_transaction!.receiptImagePath != null) ...[
                const SizedBox(height: 24),
                _buildLabel('Struk'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_transaction!.receiptImagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow(
                      'Dibuat',
                      formatDateFull(_transaction!.createdAt),
                    ),
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      'Diperbarui',
                      formatDateFull(_transaction!.updatedAt),
                    ),
                    if (_transaction!.category != null) ...[
                      const SizedBox(height: 8),
                      _buildMetaRow('Kategori', _transaction!.category!),
                    ],
                  ],
                ),
              ),

              if (_isEditing) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _storeNameController.text =
                              _transaction!.storeName;
                          _totalController.text =
                              _transaction!.total.toStringAsFixed(0);
                          _selectedDate = _transaction!.transactionDate;
                          _toggleEdit();
                        },
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
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Simpan Perubahan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: textSecondaryColor,
      ),
    );
  }

  Widget _buildValueText(String text,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: textSecondaryColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: textPrimaryColor),
          ),
        ),
      ],
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
