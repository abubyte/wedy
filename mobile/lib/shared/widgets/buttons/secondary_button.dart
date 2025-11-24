import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class WedySecondaryButton extends StatelessWidget {
  const WedySecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expanded;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final child = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingSM,
            ),
        side: const BorderSide(color: AppColors.border),
      ),
      child: _Label(
        label: label,
        icon: icon,
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: child);
    }

    return child;
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    this.icon,
  });

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextStyles.buttonLarge.copyWith(color: AppColors.primary);

    final text = Text(label, style: textStyle, textAlign: TextAlign.center);

    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme(
          data: IconTheme.of(context).copyWith(color: AppColors.primary, size: 20),
          child: icon!,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        text,
      ],
    );
  }
}
