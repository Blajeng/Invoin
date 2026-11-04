import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Loading indicator yang konsisten di seluruh app.
/// Digunakan saat:
/// - Menganalisis struk
/// - Menunggu response AI Chat
/// - Memuat data
class LoadingIndicator extends StatelessWidget {
  final String message;
  final String? secondaryMessage;

  const LoadingIndicator({
    super.key,
    this.message = 'Memuat...',
    this.secondaryMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (secondaryMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              secondaryMessage!,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
