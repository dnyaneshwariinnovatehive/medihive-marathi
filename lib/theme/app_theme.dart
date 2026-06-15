import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool isDarkMode = false;

  // ── PRIMARY PALETTE ──────────────────────
  static const Color primary        = Color(0xFF1A506C);
  static const Color primaryLight   = Color(0xFF2A6E90); // 15% lighter
  static const Color primaryLighter = Color(0xFF3A8CB4); // 30% lighter
  static const Color primaryDark    = Color(0xFF103848); // 20% darker
  static const Color primarySurface = Color(0xFFE8F2F7); // 5% tint on white

  // ── NEUTRAL PALETTE (derived from white) ─
  static const Color white          = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF4F8FA); // off-white bg
  static const Color surfaceLight    = Color(0xFFFFFFFF); // card surface
  static const Color dividerLight    = Color(0xFFE2ECF1); // subtle divider
  static const Color inputFillLight  = Color(0xFFF0F6F9); // input background

  // ── TEXT COLORS ───────────────────────────
  static const Color textPrimaryLight    = Color(0xFF1A506C); // brand color
  static const Color textSecondaryLight  = Color(0xFF4A7A92); // mid tone
  static const Color textHintLight       = Color(0xFF8AAFC0); // light hint
  static const Color textOnPrimary  = Color(0xFFFFFFFF); // white on primary

  // ── SEMANTIC COLORS ───────────────────────
  static const Color success        = Color(0xFF1A8C5B); // green tint of primary
  static const Color successSurface = Color(0xFFE8F7F0);
  static const Color error          = Color(0xFFDC2626);
  static const Color errorSurface   = Color(0xFFFEF2F2);
  static const Color warning        = Color(0xFFF0A500);
  static const Color warningSurface = Color(0xFFFFF8E8);

  // ── DARK MODE EQUIVALENTS ─────────────────
  static const Color darkBackground = Color(0xFF0D1E26); // very dark teal
  static const Color darkSurface    = Color(0xFF152838); // dark teal card
  static const Color darkCard       = Color(0xFF1C3347); // slightly lighter
  static const Color darkPrimary    = Color(0xFF2A6E90); // lighter for dark bg
  static const Color darkTextPrimary   = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0CCDA);
  static const Color darkDivider       = Color(0xFF1E3D52);

  // ── GRADIENTS ─────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A506C), Color(0xFF2A6E90)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF103848), Color(0xFF1A506C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A506C), Color(0xFF3A8CB4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient loginBgGradient = LinearGradient(
    colors: [Color(0xFFF4F8FA), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic getters to support existing widgets seamlessly
  static Color get background => isDarkMode ? darkBackground : backgroundLight;
  static Color get surface => isDarkMode ? darkSurface : surfaceLight;
  static Color get cardBg => isDarkMode ? darkCard : white;
  static Color get textPrimary => isDarkMode ? darkTextPrimary : textPrimaryLight;
  static Color get textSecondary => isDarkMode ? darkTextSecondary : textSecondaryLight;
  static Color get textHint => textHintLight;
  static Color get border => isDarkMode ? darkDivider : dividerLight;
  static Color get divider => isDarkMode ? darkDivider : dividerLight;

  static const Color danger = error; // compatibility alias
  static const Color whatsapp = Color(0xFF25D366);

  static Color get surfaceVariant => isDarkMode ? darkCard : white;
  static Color get surfaceTint => isDarkMode ? darkSurface : primarySurface;
  static Color get actionButton => isDarkMode ? darkCard : backgroundLight;
  static Color get textTertiary => textHint;

  // ─── Shadows ──────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get heavyShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ─── Spacing System ───────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ─── Border Radius ────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 100.0;

  // Compatible aliases
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusRound = 100.0;

  // ─── Typography ───────────────────────────────────────────
  static TextStyle get display => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get heading => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get subHeading => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      );

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      );

  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  // ─── ThemeData (Light Mode) ───────────────────────────────
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
        outline: Color(0xFFE2ECF1),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F8FA),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE2ECF1),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A506C),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A506C),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 14),
        )
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A506C),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFF1A506C), width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F6F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1A506C), width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626), width: 1.5)),
        hintStyle: const TextStyle(
          color: Color(0xFF8AAFC0), fontSize: 14),
        labelStyle: const TextStyle(
          color: Color(0xFF1A506C)),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF1A506C),
          fontWeight: FontWeight.w600),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F2F7),
        selectedColor: const Color(0xFF1A506C),
        labelStyle: const TextStyle(color: Color(0xFF1A506C)),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFFFFFFFF)),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── ThemeData (Dark Mode) ────────────────────────────────
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

        error: Color(0xFFDC2626),
        outline: Color(0xFF1E3D52),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1E26),
      cardColor: const Color(0xFF1C3347),
      dividerColor: const Color(0xFF1E3D52),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF103848),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF152838),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2A6E90), width: 1.5)),
        hintStyle: const TextStyle(
          color: Color(0xFF8AAFC0)),
        labelStyle: const TextStyle(
          color: Color(0xFF2A6E90)),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2A6E90),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
