import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/constants/app_dimensions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ClientSearchField extends StatelessWidget {
  const ClientSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.trailing,
    this.readOnly = false,
    this.margin,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool readOnly;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: AppTextStyles.bodyRegular,
        decoration: InputDecoration(
          prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1, size: 20, color: Color(0xFFC7CDDD)),
          suffixIcon: trailing,
          hintText: hintText ?? 'Qidirish',
          hintStyle: AppTextStyles.bodyRegular.copyWith(
            color: const Color(0xFFC7CDDD),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingSM,
            horizontal: AppDimensions.spacingXL,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: .5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: .5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: .5),
          ),
        ),
      ),
    );
  }
}
