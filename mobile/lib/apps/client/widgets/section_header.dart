import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';

class ClientSectionHeader extends StatelessWidget {
  const ClientSectionHeader({
    super.key,
    required this.title,
    this.hasAction = true,
    this.onTap,
    this.applyPadding = false,
  });

  final String title;
  final bool hasAction;
  final bool applyPadding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: applyPadding ? const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL) : EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.title2.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
            hasAction
                ? Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      border: Border.all(color: AppColors.border, width: .5),
                    ),
                    child: const Icon(IconsaxPlusLinear.arrow_right_3, color: Colors.black, size: 12),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
