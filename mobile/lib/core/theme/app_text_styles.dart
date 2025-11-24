import 'package:flutter/material.dart';

import 'app_colors.dart';

sealed class AppTextStyles {
  AppTextStyles._();

  static const _fontFamily = 'Roboto';

  static TextStyle get displayLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.18,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline1 => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.22,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline2 => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get title1 => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get title2 => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.38,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyRegular => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static TextStyle get categoryCaption => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Colors.black,
  );

  static TextStyle get buttonLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.2,
    color: AppColors.textInverse,
  );

  static TextStyle get buttonMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.textInverse,
  );
}
