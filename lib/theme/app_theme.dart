import 'package:flutter/material.dart';

class AppColors {
  // ── Core purple ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryDark = Color(0xFF4A32CC);
  static const Color primaryLight = Color(0xFFD4C5F9);
  static const Color buttonSoft = Color(0xFFE8DEFF);

  // ── Parchment palette ──────────────────────────────────────────────────────
  // Warm tones pulled from the logo's book/page glow.
  static const Color parchment = Color(0xFFF5EFE0);        // main bg
  static const Color parchmentLight = Color(0xFFFAF6ED);    // cards/surfaces
  static const Color parchmentDark = Color(0xFFEDE4D3);     // dividers/subtle bg
  static const Color parchmentAccent = Color(0xFFD4C4A0);   // decorative borders

  // ── Brown-gold bridge tones ────────────────────────────────────────────────
  static const Color goldDark = Color(0xFF8B7340);          // text on parchment
  static const Color goldMid = Color(0xFFBA9A5C);           // accents/icons
  static const Color goldLight = Color(0xFFD4BB82);         // soft accents

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5EFE0);        // parchment bg
  static const Color surface = Color(0xFFFAF6ED);           // card surface

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C2416);       // warm near-black
  static const Color textSecondary = Color(0xFF7A6F5F);     // warm muted

  // ── Input ──────────────────────────────────────────────────────────────────
  static const Color inputBorder = Color(0xFFDDD4C4);       // warm border
  static const Color inputFill = Color(0xFFFAF6ED);         // matches surface

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle:
      const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
      ),
    ),
    dividerColor: AppColors.parchmentDark,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.parchmentDark, width: 0.5),
      ),
    ),
  );
}