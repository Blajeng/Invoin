import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';

/// Service untuk AI Chat
///
/// 1. User kirim pertanyaan
/// 2. App logic menentukan periode/filter
/// 3. App ambil transaksi relevan
/// 4. App hitung angka deterministik
/// 5. Context dikirim ke AI
/// 6. AI menghasilkan jawaban
class ChatService {
  final TransactionService _transactionService;
  final _uuid = const Uuid();

  // Riwayat chat per-sesi (hilang saat app restart)
  final List<ChatMessage> _messages = [];

  ChatService(this._transactionService);

  /// Ambil semua pesan chat saat ini.
  List<ChatMessage> getMessages() {
    return List.unmodifiable(_messages);
  }

  /// Kirim pertanyaan user dan dapatkan jawaban.
  Future<ChatMessage> sendMessage(String userQuestion) async {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: userQuestion,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // Simulasi delay AI
    await Future.delayed(const Duration(seconds: 1));

    final allTransactions = _transactionService.getAllTransactions();
    final monthTransactions = _transactionService.getCurrentMonthTransactions();
    final monthTotal = _transactionService.getCurrentMonthTotal();

    String responseText;

    if (allTransactions.isEmpty) {
      responseText =
          'Belum ada transaksi yang tercatat. '
          'Coba scan struk belanja untuk mulai mencatat pengeluaran kamu.';
    } else {
      responseText =
          'Berdasarkan data transaksi kamu:\n\n'
          '• Total transaksi tercatat: ${allTransactions.length} transaksi\n'
          '• Transaksi bulan ini: ${monthTransactions.length} transaksi\n'
          '• Total pengeluaran bulan ini: ${formatCurrency(monthTotal)}\n\n'
         ;
    }

    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      content: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(aiMsg);

    return aiMsg;
  }

  /// Bersihkan riwayat chat.
  void clearMessages() {
    _messages.clear();
  }
}
