import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool isDarkMode = false;

  // ── LIGHT MODE PALETTE ──────────────────────
  static const Color lightBackground    = Color(0xFFF4F8FA);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightPrimary       = Color(0xFF1A506C);
  static const Color lightSecondary     = Color(0xFF2A6E90);
  static const Color lightAccent        = Color(0xFF3A8CB4);
  static const Color lightTextPrimary   = Color(0xFF1A506C);
  static const Color lightTextSecondary = Color(0xFF4A7A92);
  static const Color lightTextHint      = Color(0xFF8AAFC0);
  static const Color lightBorder        = Color(0xFFE2ECF1);
  static const Color lightDivider       = Color(0xFFE2ECF1);
  static const Color lightInputBg       = Color(0xFFF0F6F9);

  // ── DARK MODE PALETTE ───────────────────────
  static const Color darkBackground    = Color(0xFF0D1E26);
  static const Color darkSurface       = Color(0xFF152838);
  static const Color darkCard          = Color(0xFF1C3347);
  static const Color darkPrimary       = Color(0xFF2A6E90);
  static const Color darkSecondary     = Color(0xFF3A8CB4);
  static const Color darkAccent        = Color(0xFFB76E79);
  static const Color darkTextPrimary   = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0CCDA);
  static const Color darkTextHint      = Color(0xFF8AAFC0);
  static const Color darkBorder        = Color(0xFF1E3D52);
  static const Color darkDivider       = Color(0xFF1E3D52);
  static const Color darkInputBg       = Color(0xFF152838);

  // ── COMMON COLORS (used in const contexts) ──
  static const Color primary        = Color(0xFF1A506C);
  static const Color primaryLight   = Color(0xFF2A6E90);
  static const Color primaryLighter = Color(0xFF3A8CB4);
  static const Color primaryDark    = Color(0xFF103848);
  static const Color primarySurface = Color(0xFFE8F2F7);

  // ── TEXT COLORS ──────────────────────────────
  static const Color textOnPrimary    = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A506C);
  static const Color textSecondaryLight = Color(0xFF4A7A92);
  static const Color textHintLight    = Color(0xFF8AAFC0);

  // ── SEMANTIC COLORS ─────────────────────────
  static const Color success        = Color(0xFF1A8C5B);
  static const Color successLight   = Color(0xFF2DAF7A);
  static const Color successSurface = Color(0xFFE8F7F0);
  static const Color error          = Color(0xFFDC2626);
  static const Color errorLight     = Color(0xFFEF4444);
  static const Color errorSurface   = Color(0xFFFEF2F2);
  static const Color warning        = Color(0xFFF0A500);
  static const Color warningLight   = Color(0xFFF5B840);
  static const Color warningSurface = Color(0xFFFFF8E8);

  // ── ADDITIONAL COLORS ───────────────────────
  static const Color blue           = Color(0xFF2196F3);
  static const Color blueLight      = Color(0xFF64B5F6);

  // ── GRADIENTS ───────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A506C), Color(0xFF2A6E90)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldCopperGradient = LinearGradient(
    colors: [Color(0xFFC9A96E), Color(0xFFB87351)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldRoseGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB76E79)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF103848), Color(0xFF1A506C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient loginBgGradient = LinearGradient(
    colors: [Color(0xFFF4F8FA), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── DYNAMIC GETTERS (mode-aware) ────────────
  static Color get background => isDarkMode ? darkBackground : lightBackground;
  static Color get surface => isDarkMode ? darkSurface : lightSurface;
  static Color get cardBg => isDarkMode ? darkCard : lightSurface;
  static Color get textPrimary => isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textHint => isDarkMode ? darkTextHint : lightTextHint;
  static Color get border => isDarkMode ? darkBorder : lightBorder;
  static Color get divider => isDarkMode ? darkDivider : lightDivider;
  static Color get inputBg => isDarkMode ? darkInputBg : lightInputBg;
  static Color get surfaceVariant => isDarkMode ? darkCard : lightSurface;
  static Color get surfaceTint => isDarkMode ? darkSurface : primarySurface;
  static Color get actionButton => isDarkMode ? darkCard : lightBorder;
  static Color get textTertiary => textHint;

  static Color get danger => isDarkMode ? errorLight : error;
  static const Color whatsapp = Color(0xFF25D366);

  // ─── SHADOWS (warm undertone) ───────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get heavyShadow => [
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: const Color(0xFF1A506C).withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  // ─── SPACING ─────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ─── BORDER RADIUS ───────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 100.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusRound = 100.0;

  // ─── TYPOGRAPHY ──────────────────────────────
  static TextStyle get display => GoogleFonts.nunito(
        fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary,
        letterSpacing: -0.5, height: 1.2,
      );
  static TextStyle get displaySmall => GoogleFonts.nunito(
        fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary,
        letterSpacing: -0.3, height: 1.25,
      );
  static TextStyle get heading => GoogleFonts.nunito(
        fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary,
        letterSpacing: -0.3, height: 1.3,
      );
  static TextStyle get subHeading => GoogleFonts.nunito(
        fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary,
        letterSpacing: -0.2, height: 1.35,
      );
  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.normal, color: textPrimary,
        letterSpacing: 0.1, height: 1.5,
      );
  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.normal, color: textPrimary,
        letterSpacing: 0.1, height: 1.4,
      );
  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.normal, color: textSecondary,
        letterSpacing: 0.2, height: 1.4,
      );
  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary,
        letterSpacing: 0.2,
      );
  static TextStyle get overline => GoogleFonts.nunito(
        fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary,
        letterSpacing: 0.5, height: 1.3,
      );

  // ─── THEMEDATA (LIGHT) ──────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A506C),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF2A6E90),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1A506C),
        error: Color(0xFFDC2626),
        onError: Color(0xFFFFFFFF),
        outline: Color(0xFFE2ECF1),
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.light(useMaterial3: true).textTheme,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F8FA),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE2ECF1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A506C),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0, centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF), fontSize: 18,
          fontWeight: FontWeight.bold, letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A506C),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A506C),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF1A506C), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F6F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A506C), width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
        hintStyle: const TextStyle(color: Color(0xFF8AAFC0), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF1A506C)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF1A506C), fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F2F7),
        selectedColor: const Color(0xFF1A506C),
        labelStyle: const TextStyle(color: Color(0xFF1A506C)),
        secondaryLabelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF1A506C),
        unselectedItemColor: Color(0xFF8AAFC0),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF1A506C),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── THEMEDATA (DARK) ───────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2A6E90),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF3A8CB4),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFF1C3347),
        onSurface: Color(0xFFFFFFFF),
        error: Color(0xFFEF4444),
        onError: Color(0xFFFFFFFF),
        outline: Color(0xFF1E3D52),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1E26),
      cardColor: const Color(0xFF1C3347),
      dividerColor: const Color(0xFF1E3D52),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF152838),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0, centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF152838),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A6E90), width: 1.5)),
        hintStyle: const TextStyle(color: Color(0xFF8AAFC0)),
        labelStyle: const TextStyle(color: Color(0xFF2A6E90)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2A6E90),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF2A6E90), width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF152838),
        selectedItemColor: Color(0xFF2A6E90),
        unselectedItemColor: Color(0xFF8AAFC0),
      ),
    );
  }
}
