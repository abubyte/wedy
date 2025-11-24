import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class OtpInputWidget extends StatelessWidget {
  const OtpInputWidget({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: AppTextStyles.headline2,
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••••',
        hintStyle: AppTextStyles.headline2.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spacingSM,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
