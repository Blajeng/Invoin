import 'package:flutter/material.dart';

/// Nama aplikasi
const String appName = 'Invoin';

/// Primary
const Color primaryColor = Color(0xFF005C55);
const Color primaryContainerColor = Color(0xFF0F766E);

/// Secondary
const Color secondaryColor = Color(0xFF006B5F);
const Color secondaryContainerColor = Color(0xFF6DF5E1);

/// Tertiary
const Color tertiaryColor = Color(0xFF734700);
const Color tertiaryContainerColor = Color(0xFF945D00);

/// Surface
const Color surfaceColor = Color(0xFFFAF8FF);
const Color surfaceContainerLowColor = Color(0xFFF2F3FF);
const Color surfaceContainerColor = Color(0xFFEAEDFF);
const Color surfaceContainerHighestColor = Color(0xFFDAE2FD);

/// Error
const Color errorContainerColor = Color(0xFFFFDAD6);

/// Warna utama aplikasi — deep teal.
const Color primaryDarkColor = primaryContainerColor;

/// Warna background
const Color scaffoldBackgroundColor = surfaceColor;
const Color cardColor = Colors.white;

/// Warna teks
const Color textPrimaryColor = Color(0xFF131B2E);
const Color textSecondaryColor = Color(0xFF64748B);

/// Warna status
const Color successColor = Color(0xFF22C55E);
const Color errorColor = Color(0xFFBA1A1A);
const Color warningColor = Color(0xFFF59E0B);

/// Aksen — belum ada padanan di design specification.
const Color accentColor = Color(0xFFF59E0B);

/// Primary light — belum ada padanan di design specification.
const Color primaryLightColor = Color(0xFF5EEAD4);

/// Global font family.
const String appFontFamily = 'Plus Jakarta Sans';

/// Weight foundation.
const FontWeight appFontWeightRegular = FontWeight.w400;
const FontWeight appFontWeightMedium = FontWeight.w500;
const FontWeight appFontWeightSemiBold = FontWeight.w600;
const FontWeight appFontWeightBold = FontWeight.w700;

/// Currency typography.
class AppCurrencyTypography {
  const AppCurrencyTypography._();

  /// Currency display — 28px, bold.
  static const double displayFontSize = 28;
  static const TextStyle display = TextStyle(
    fontSize: displayFontSize,
    fontWeight: appFontWeightBold,
  );

  /// Currency small — 16px, bold.
  static const double smallFontSize = 16;
  static const TextStyle small = TextStyle(
    fontSize: smallFontSize,
    fontWeight: appFontWeightBold,
  );
  
  static const double prefixScale = 0.85;
  static double prefixFontSize(double currencyFontSize) =>
      currencyFontSize * prefixScale;
}

/// Radius dasar mengikuti design specification.
class AppRadius {
  const AppRadius._();

  /// Button dan input — 12–14.
  static const double control = 12;
  static const double controlLarge = 14;

  /// Card — 16–20.
  static const double card = 16;
  static const double cardLarge = 20;

  /// Pill / badge — fully rounded.
  static const double pill = 9999;
}

/// Ritme dasar 4dp.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Margin horizontal layar — umumnya 16–20.
  static const double screenHorizontal = 20;
}
