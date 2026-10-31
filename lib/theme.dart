import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const brand = Color(0xFF0F766E);
  static const brandDeep = Color(0xFF134E4A);
  static const brandLight = Color(0xFF14B8A6);
  static const accent = Color(0xFFFF7A59);
  static const background = Color(0xFFF6F7F9);
  static const field = Color(0xFFF1F4F7);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
}

const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.brandLight, AppColors.brand, AppColors.brandDeep],
);

const softShadow = [
  BoxShadow(color: Color(0x0F0F172A), blurRadius: 24, offset: Offset(0, 8)),
];

OutlineInputBorder _border(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    secondary: AppColors.accent,
    surface: Colors.white,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = GoogleFonts.plusJakartaSansTextTheme(
    base.textTheme,
  ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  final selected = WidgetState.selected;

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _border(Colors.transparent),
      enabledBorder: _border(Colors.transparent),
      focusedBorder: _border(AppColors.brand, 1.6),
      errorBorder: _border(scheme.error),
      focusedErrorBorder: _border(scheme.error, 1.6),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.7)),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.line, width: 1.4),
        foregroundColor: AppColors.ink,
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.brand.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(selected) ? AppColors.brand : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(selected) ? AppColors.brand : AppColors.muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      rangeSelectionBackgroundColor: AppColors.brand.withValues(alpha: 0.12),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      space: 1,
      thickness: 1,
    ),
  );
}
