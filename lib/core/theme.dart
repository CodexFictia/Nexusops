import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF818CF8);      // Soft indigo
  static const Color primaryDark = Color(0xFF6366F1);  // Deep indigo
  static const Color sidebar = Color(0xFF1E1B4B);      // Deep indigo sidebar
  static const Color sidebarHover = Color(0xFF312E81);
  static const Color sidebarText = Color(0xFFA5B4FC);  // Light indigo
  static const Color surface = Color(0xFFF5F3FF);      // Warm indigo-tinted surface
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E1B4B);  // Dark indigo
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF34D399);      // Pastel emerald
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFFBBF24);      // Pastel amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFF87171);        // Pastel rose
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF60A5FA);         // Pastel sky blue
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          surface: AppColors.surface,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black87,
            elevation: 0,
            textStyle: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
            color: AppColors.divider, thickness: 1, space: 1),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.card,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      );
}
