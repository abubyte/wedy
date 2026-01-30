import 'package:flutter/material.dart';
import 'package:wedy/core/constants/app_dimensions.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'primary_button.dart';

class WedyEmptyState extends StatelessWidget {
  const WedyEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.asset,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final Widget? asset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null) ...[SizedBox(height: 120, child: asset), const SizedBox(height: AppDimensions.spacingL)],
          Text(title, style: AppTextStyles.title1, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.spacingL),
            WedyPrimaryButton(label: actionLabel!, onPressed: onAction, expanded: false),
          ],
        ],
      ),
    );
  }
}
