import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';

sealed class PinputTheme {
  static final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
    ),
  );

  static final focusedPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.textPrimary, width: 2)),
    ),
  );
  static final submittedPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.textPrimary, width: 2)),
    ),
  );
  static final errorPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.error, width: 2)),
    ),
  );
}
