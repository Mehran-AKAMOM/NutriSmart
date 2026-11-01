import 'package:flutter/material.dart';

/// NutriSmart design tokens: soft lavender-grey canvas, bold black type,
/// deep-violet hero colour and an electric-lime accent.
class AppColors {
  static const bg = Color(0xFFF2F1F6);
  static const surface = Colors.white;
  static const ink = Color(0xFF15131C);
  static const ink2 = Color(0xFF2C2935);
  static const muted = Color(0xFF8E8A99);
  static const line = Color(0xFFE6E4EC);

  // Brand: deep violet + electric lime
  static const violet = Color(0xFF5B34F2);
  static const violetSoft = Color(0xFF8C72FF);
  static const lime = Color(0xFFC8F23A);
  static const limeDark = Color(0xFF6E9800);

  // Semantic colours
  static const primary = violet;
  static const protein = violet;
  static const carbs = Color(0xFFFFAE1F);
  static const fat = Color(0xFFFF5C8D);
  static const fiber = limeDark;
  static const water = violetSoft;
  static const warning = Color(0xFFFFAE1F);
  static const danger = Color(0xFFFF4757);

  // Kept for older widgets
  static const green = violet;
  static const greenDark = ink;
}

/// Shared text styles.
class AppText {
  static const display = TextStyle(
      fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -1.2, height: 1.05);
  static const h1 = TextStyle(
      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.8);
  static const h2 = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.3);
  static const body = TextStyle(fontSize: 14, color: AppColors.ink2, height: 1.35);
  static const small = TextStyle(fontSize: 12, color: AppColors.muted);
  static const label = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink);
}

ThemeData buildTheme(Brightness brightness) {
  // The design is light-first; dark mode uses the same light palette so
  // screenshots always look the same.
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.violet,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.violet,
    onPrimary: Colors.white,
    secondary: AppColors.ink,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    surfaceContainerHighest: AppColors.line,
    outlineVariant: AppColors.line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.h2,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    dividerColor: AppColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      floatingLabelStyle: const TextStyle(color: AppColors.violet),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.ink,
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 13),
      secondaryLabelStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.violet : AppColors.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: StadiumBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.violet),
  );
}
