import 'package:flutter/material.dart';

// ── Pro-Act Color Palette ──────────────────────────────────────────────────
class AppColors {
  // Backgrounds - layered dark surfaces
  static const background    = Color(0xFF0A0A0A); // near-black canvas
  static const surface       = Color(0xFF141414); // cards, sheets
  static const surfaceRaised = Color(0xFF1E1E1E); // elevated elements

  // Accent - the single brand color (electric amber - energy, urgency)
  static const accent        = Color(0xFFE8A020);
  static const accentMuted   = Color(0xFF3D2A00);

  // Semantic colors
  static const success       = Color(0xFF4CAF72); // task done
  static const danger        = Color(0xFFE84040); // failed / wheel
  static const warning       = Color(0xFFE8A020); // streak at risk

  // Text hierarchy
  static const textPrimary   = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textMuted     = Color(0xFF4A4A4A);

  // Borders
  static const border        = Color(0xFF242424);
  static const borderActive  = Color(0xFF3A3A3A);
}

// ── Typography ────────────────────────────────────────────────────────────
class AppTextStyles {
  static const displayLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const displayMedium = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const titleLarge = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const titleMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.6,
  );
  static const bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textMuted, letterSpacing: 0.8,
  );
}

// ── Theme ─────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),

    // App bar - invisible, content bleeds to top
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLarge,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    // Buttons - primary action
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1),
      ),
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
      space: 0,
    ),

    fontFamily: 'Inter',
  );
}