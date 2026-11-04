import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../services/chat_service.dart';
import '../services/transaction_service.dart';
import 'home_screen.dart';
import 'transaction_history_screen.dart';
import 'chat_screen.dart';

/// Main Shell — struktur navigasi utama Invoin.
///
/// Menyediakan bottom navigation persisten dengan 3 destination utama:
/// Invoin
/// ├── Beranda  → HomeScreen
/// ├── Transaksi → TransactionHistoryScreen
/// └── AI Chat   → ChatScreen
/// 
/// Beranda merupakan destination default
class MainShell extends StatefulWidget {
  final TransactionService transactionService;
  final ChatService chatService;

  const MainShell({
    super.key,
    required this.transactionService,
    required this.chatService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// 0 = Beranda, 1 = Transaksi, 2 = AI Chat
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(transactionService: widget.transactionService),
            TransactionHistoryScreen(
              transactionService: widget.transactionService,
            ),
            ChatScreen(chatService: widget.chatService),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: cardColor,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
        ],
      ),
    );
  }
}
