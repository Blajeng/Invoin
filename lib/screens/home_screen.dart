import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../services/transaction_service.dart';

/// Home Screen — Dashboard / Navigation Hub
/// - Overview sederhana
/// - Akses cepat ke receipt capture/upload
/// - Akses ke riwayat transaksi
/// - Akses ke AI Chat
/// Dashboard hanya menampilkan ringkasan minimal: total pengeluaran bulan ini + jumlah transaksi.
class HomeScreen extends StatefulWidget {
  final TransactionService transactionService;

  const HomeScreen({
    super.key,
    required this.transactionService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final monthTransactions =
        widget.transactionService.getCurrentMonthTransactions();
    final monthTotal = widget.transactionService.getCurrentMonthTotal();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pencatatan keuangan dari struk',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondaryColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, primaryDarkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengeluaran Bulan Ini',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(monthTotal),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${monthTransactions.length} transaksi',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  _buildActionCard(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan Struk',
                    subtitle: 'Foto & analisis otomatis',
                    color: primaryColor,
                    onTap: () =>
                        Navigator.pushNamed(context, '/receipt-upload'),
                  ),
                  _buildActionCard(
                    icon: Icons.history,
                    label: 'Riwayat',
                    subtitle: 'Lihat transaksi',
                    color: const Color(0xFF6366F1),
                    onTap: () =>
                        Navigator.pushNamed(context, '/transaction-history'),
                  ),
                  _buildActionCard(
                    icon: Icons.chat_outlined,
                    label: 'AI Chat',
                    subtitle: 'Tanya keuangan',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/transaction-history'),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),

              if (monthTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: textSecondaryColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mulai dengan scan struk belanja kamu',
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...monthTransactions.take(3).map(
                      (t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/transaction-detail',
                            arguments: t.id,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      primaryLightColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.storeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      formatDate(t.transactionDate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCurrency(t.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryDarkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: textSecondaryColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
