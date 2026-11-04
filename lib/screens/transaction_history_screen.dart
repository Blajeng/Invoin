import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../widgets/transaction_card.dart';
import '../utils/constants.dart';

/// Transaction History Screen
/// - Menampilkan daftar transaksi tersimpan
/// - Setiap item menampilkan informasi ringkas yang relevan
/// - Data berasal dari sumber data aplikasi, bukan hasil AI yang tidak tersimpan
/// - User dapat membuka detail transaksi
class TransactionHistoryScreen extends StatefulWidget {
  final TransactionService transactionService;

  const TransactionHistoryScreen({
    super.key,
    required this.transactionService,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final transactions = widget.transactionService.getAllTransactions();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: textSecondaryColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transaksi yang sudah disimpan akan muncul di sini',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/receipt-upload'),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan Struk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return TransactionCard(
                  transaction: transaction,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/transaction-detail',
                      arguments: transaction.id,
                    );
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
    );
  }
}
