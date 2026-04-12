import 'package:flutter/material.dart';
import '../widgets/app_language.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AppTheme — a bundle of UI colours for one brightness mode.
//
//  Two built-in themes are available as constants:
//    AppTheme.dark   (index 0, default)
//    AppTheme.light  (index 1)
//
//  Accent colours are stored per-language in [accents], indexed by
//  AppLanguage.index (navi=0, klingon=1, highValyrian=2).
//
//  Global theme selection is via [appThemeIndex] — a plain ValueNotifier<int>.
//  Update its value from the settings UI; MaterialApp rebuilds automatically.
//  No service class, no SharedPreferences, no ChangeNotifier boilerplate.
// ═══════════════════════════════════════════════════════════════════════════

/// Active theme index. 0 = dark (default), 1 = light.
/// Write [appThemeIndex.value] from the Settings tab to switch themes.
final ValueNotifier<int> appThemeIndex = ValueNotifier(0);

class AppTheme {
  final Brightness brightness;
  final Color background;
  final Color surface;       // raised cards / tiles
  final Color surfaceAlt;    // secondary surface (input fills, chips)
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color overlayScrim;  // backdrop for modals / dialogs

  const AppTheme({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.overlayScrim,
  });

  bool get isDark => brightness == Brightness.dark;

  // ── Theme list ─────────────────────────────────────────────────────────────
  // Index matches [appThemeIndex.value]: 0 = dark, 1 = light.
  static const List<AppTheme> themes = [dark, light];

  // ── Accent colours ─────────────────────────────────────────────────────────
  // Indexed by AppLanguage.index: 0 = navi, 1 = klingon, 2 = highValyrian.
  static const List<Color> accents = [
    Color(0xFF80D8FF), // Na'vi
    Color(0xFF9B1C1C), // Klingon
    Color(0xFFB8860B), // High Valyrian
  ];

  /// Convenience accessor — identical to AppLanguage.accentColor.
  static Color accentFor(AppLanguage language) => accents[language.index];

  // ── Context lookup ─────────────────────────────────────────────────────────
  /// Returns the active AppTheme based on the inherited Material brightness.
  static AppTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static const AppTheme dark = AppTheme(
    brightness:    Brightness.dark,
    background:    Color(0xFF0D0D0D),
    surface:       Color(0xFF1A1A1A),
    surfaceAlt:    Color(0xFF2A2A2A),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFFBBBBBB),
    textMuted:     Color(0xFF777777),
    border:        Color(0xFF333333),
    divider:       Color(0xFF2A2A2A),
    overlayScrim:  Color(0xCC000000),
  );

  // ── Light theme ────────────────────────────────────────────────────────────
  static const AppTheme light = AppTheme(
    brightness:    Brightness.light,
    background:    Color(0xFFF5EFE0), // parchment
    surface:       Color(0xFFFFFFFF),
    surfaceAlt:    Color(0xFFFAF6ED),
    textPrimary:   Color(0xFF2C2416),
    textSecondary: Color(0xFF7A6F5F),
    textMuted:     Color(0xFFAFA593),
    border:        Color(0xFFDDD4C4),
    divider:       Color(0xFFEDE4D3),
    overlayScrim:  Color(0x99000000),
  );

  // ── Material ThemeData builder ─────────────────────────────────────────────
  /// Converts this palette into a Flutter [ThemeData].
  /// Call once and cache — [ColorScheme.fromSeed] is non-trivial.
  ThemeData toMaterialTheme(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(primary: accent, surface: surface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
      dividerColor: divider,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  AppColors — legacy static-const values kept for screens not yet migrated
//  to AppTheme. Prefer AppTheme.of(context).someColor for new code.
// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  static const Color primary         = Color(0xFF6B4EFF);
  static const Color primaryDark     = Color(0xFF4A32CC);
  static const Color primaryLight    = Color(0xFFD4C5F9);
  static const Color buttonSoft      = Color(0xFFE8DEFF);
  static const Color parchment       = Color(0xFFF5EFE0);
  static const Color parchmentLight  = Color(0xFFFAF6ED);
  static const Color parchmentDark   = Color(0xFFEDE4D3);
  static const Color parchmentAccent = Color(0xFFD4C4A0);
  static const Color goldDark        = Color(0xFF8B7340);
  static const Color goldMid         = Color(0xFFBA9A5C);
  static const Color goldLight       = Color(0xFFD4BB82);
  static const Color background      = Color(0xFFF5EFE0);
  static const Color surface         = Color(0xFFFAF6ED);
  static const Color textPrimary     = Color(0xFF2C2416);
  static const Color textSecondary   = Color(0xFF7A6F5F);
  static const Color inputBorder     = Color(0xFFDDD4C4);
  static const Color inputFill       = Color(0xFFFAF6ED);
  static const Color success         = Color(0xFF4CAF50);
  static const Color error           = Color(0xFFE53935);
  static const Color warning         = Color(0xFFFFC107);
}
