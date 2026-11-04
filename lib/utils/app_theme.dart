import 'package:flutter/material.dart';

import 'constants.dart';

/// Theme global Invoin.
class AppTheme {
  const AppTheme._();
  static ColorScheme buildColorScheme() {
    final base = ColorScheme.fromSeed(seedColor: primaryColor);

    return base.copyWith(
      primary: primaryColor,
      primaryContainer: primaryContainerColor,
      secondary: secondaryColor,
      secondaryContainer: secondaryContainerColor,
      tertiary: tertiaryColor,
      tertiaryContainer: tertiaryContainerColor,
      surface: surfaceColor,
      surfaceContainerLow: surfaceContainerLowColor,
      surfaceContainer: surfaceContainerColor,
      surfaceContainerHighest: surfaceContainerHighestColor,
      onSurface: textPrimaryColor,
      error: errorColor,
      errorContainer: errorContainerColor,
    );
  }

  /// Text theme dengan global font family Plus Jakarta Sans.
  static TextTheme buildTextTheme(ColorScheme scheme) {
    final base = Typography.material2021(
      colorScheme: scheme,
    ).black.apply(fontFamily: appFontFamily);

    return base.copyWith(
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: appFontWeightRegular,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: appFontWeightRegular,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: appFontWeightMedium,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: appFontWeightSemiBold,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: appFontWeightBold,
      ),
    );
  }

  /// ThemeData utama aplikasi.
  static ThemeData light() {
    final scheme = buildColorScheme();
    final textTheme = buildTextTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: appFontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
