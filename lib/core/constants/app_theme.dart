import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.aqua,
        onPrimary: AppColors.deepOcean,
        secondary: AppColors.seafoam,
        onSecondary: AppColors.deepOcean,
        surface: AppColors.darkOcean,
        onSurface: AppColors.pearl,
        error: AppColors.coral,
        onError: AppColors.white,
        outline: AppColors.teal,
      ),
      scaffoldBackgroundColor: AppColors.deepOcean,
      textTheme: GoogleFonts.fredokaTextTheme().apply(
        bodyColor: AppColors.pearl,
        displayColor: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pearl),
        titleTextStyle: GoogleFonts.fredoka(
          color: AppColors.pearl,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.oceanBlue.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(
            color: AppColors.teal,
            width: 2.5, // Çizgi film stili daha kalın kenarlık
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aqua,
          foregroundColor: AppColors.deepOcean,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Yuvarlak tombul butonlar
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.aqua),
      dividerTheme: DividerThemeData(
        color: AppColors.teal.withValues(alpha: 0.25),
        thickness: 2, // Daha kalın ayraçlar
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.oceanBlue.withValues(alpha: 0.6),
        labelStyle: GoogleFonts.fredoka(
          color: AppColors.lightAqua,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.teal, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.oceanBlue,
        contentTextStyle: GoogleFonts.fredoka(color: AppColors.pearl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.fredoka(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.fredoka(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineLarge => GoogleFonts.fredoka(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.pearl,
        letterSpacing: 0,
      );

  static TextStyle get headlineMedium => GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.pearl,
      );

  static TextStyle get titleLarge => GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.pearl,
      );

  static TextStyle get titleMedium => GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.silver,
      );

  // Açıklama metinleri daha okunaklı olması için Nunito olarak ayarlandı
  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.silver,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.silver,
        height: 1.5,
      );

  static TextStyle get labelSmall => GoogleFonts.fredoka(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.teal,
        letterSpacing: 1.2,
      );

  static TextStyle get aquaAccent => GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.aqua,
      );
}
