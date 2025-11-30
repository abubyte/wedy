import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';

class WedyCircularButton extends StatelessWidget {
  final IconData? icon;
  final double size;
  final double? iconSize;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color? color;
  final Color? borderColor;

  const WedyCircularButton({
    super.key,
    this.icon,
    this.size = 43,
    this.onTap,
    this.isPrimary = false,
    this.iconSize,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.pop(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          color: color ?? (isPrimary ? AppColors.primary : AppColors.surface),
          border: Border.all(color: borderColor ?? (isPrimary ? AppColors.primaryDark : AppColors.border), width: .5),
        ),
        child: Center(
          child: Icon(
            icon ?? IconsaxPlusLinear.arrow_left_1,
            color: isPrimary ? AppColors.surface : Colors.black,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
