import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/theme/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.hasAction = true});

  final String title;
  final bool hasAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.title2.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        hasAction
            ? Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
                ),
                child: const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: Colors.black,
                  size: 12,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
