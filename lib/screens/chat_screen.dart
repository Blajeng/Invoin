import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/loading_indicator.dart';
import '../utils/constants.dart';

/// AI Chat Screen
/// - Menampilkan conversation dan input pertanyaan
/// - User dapat mengirim pertanyaan melalui chat
/// - AI menghasilkan jawaban natural-language berdasarkan context transaksi
class ChatScreen extends StatefulWidget {
  final ChatService chatService;

  const ChatScreen({
    super.key,
    required this.chatService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    // Cegah pengiriman ganda.
    // Tombol send sudah dinonaktifkan saat `_isLoading`, tapi aksi "send" dari
    // keyboard (`onSubmitted`) tetap aktif. Kalau user mengetik pertanyaan baru
    // selagi jawaban sebelumnya sedang diproses, dua request akan berjalan
    // bersamaan dan balasannya saling tumpang tindih.
    // Guard ini membuat kedua jalur konsisten dengan tombol send. Teks yang
    // diketik user tetap ada di field (tidak ikut terkirim), jadi pertanyaan itu
    // tetap bisa dikirim setelah loading selesai.
    if (_isLoading) return;

    final question = _inputController.text.trim();
    if (question.isEmpty) return;

    _inputController.clear();

    setState(() => _isLoading = true);

    try {
      await widget.chatService.sendMessage(question);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan jawaban. Coba lagi.'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.chatService.getMessages();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: primaryColor, size: 22),
            SizedBox(width: 8),
            Text('AI Chat'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                widget.chatService.clearMessages();
                setState(() {});
              },
              tooltip: 'Hapus riwayat chat',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child:
                              LoadingIndicator(message: 'AI sedang berpikir...'),
                        );
                      }
                      return ChatBubble(message: messages[index]);
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Tanya tentang keuanganmu...',
                        hintStyle: TextStyle(
                          color: textSecondaryColor.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_outlined,
                size: 40,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tanya AI tentang keuanganmu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contoh: "Berapa pengeluaran saya bulan ini?"',
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Berapa pengeluaran bulan ini?'),
                _buildSuggestionChip('Ringkasan transaksi'),
                _buildSuggestionChip('Transaksi terbesar'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, color: primaryColor),
      ),
      backgroundColor: primaryColor.withValues(alpha: 0.08),
      side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
      onPressed: () {
        _inputController.text = text;
        _sendMessage();
      },
    );
  }
}
