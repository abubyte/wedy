import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class WedyPrimaryButton extends StatelessWidget {
  const WedyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expanded;
  final bool loading;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final child = _buildContent(context);

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: child,
      );
    }

    return child;
  }

  Widget _buildContent(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingSM,
            ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: loading
            ? const SizedBox(
                key: ValueKey('loading'),
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : _Label(
                key: const ValueKey('label'),
                label: label,
                icon: icon,
              ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.buttonLarge,
      textAlign: TextAlign.center,
    );

    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme(
          data: IconTheme.of(context).copyWith(size: 20),
          child: icon!,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        text,
      ],
    );
  }
}
