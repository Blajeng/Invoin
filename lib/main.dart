import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'screens/main_shell.dart';
import 'screens/receipt_upload_screen.dart';
import 'screens/transaction_review_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/chat_screen.dart';
import 'repositories/transaction_repository.dart';
import 'services/transaction_service.dart';
import 'services/receipt_service.dart';
import 'services/chat_service.dart';

void main() {
  initializeDateFormatting('id_ID');

  runApp(const InvoinApp());
}

class InvoinApp extends StatelessWidget {
  const InvoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = TransactionRepository();
    final transactionService = TransactionService(repository);
    final receiptService = ReceiptService(repository);
    final chatService = ChatService(transactionService);

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: MainShell(
        transactionService: transactionService,
        chatService: chatService,
      ),
      routes: {
        '/receipt-upload': (context) =>
            ReceiptUploadScreen(receiptService: receiptService),
        '/transaction-history': (context) =>
            TransactionHistoryScreen(transactionService: transactionService),
        '/transaction-detail': (context) =>
            TransactionDetailScreen(transactionService: transactionService),
        '/chat': (context) => ChatScreen(chatService: chatService),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/transaction-review') {
          return MaterialPageRoute(
            builder: (context) =>
                TransactionReviewScreen(receiptService: receiptService),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
