import 'dart:ui';

sealed class AppColors {
  AppColors._();

  // Brand.
  static const primary = Color(0xFF5A8EF4);
  static const primaryDark = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFD3E3FD);

  // Semantic.
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFCC0000);
  static const info = Color(0xFF0EA5E9);

  // Neutrals.
  static const background = Color(0xFFF1F5FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F9FC);
  static const border = Color(0xFFE0E0E0);
  static const borderStrong = Color(0xFFCBD5F5);

  // Text.
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const textInverse = Color(0xFFFFFFFF);
  static const textError = Color(0xFFFF6666);

  // Misc.
  static const overlay = Color(0xCC0F172A);
  static const shadow = Color(0x1A111827);
}
