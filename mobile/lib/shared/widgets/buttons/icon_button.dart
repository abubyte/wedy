import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class WedyIconButton extends StatelessWidget {
  const WedyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
    this.elevation = 0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      shape: const CircleBorder(),
      elevation: elevation,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textPrimary,
            size: size / 2 + AppDimensions.spacingXS,
          ),
        ),
      ),
    );
  }
}
