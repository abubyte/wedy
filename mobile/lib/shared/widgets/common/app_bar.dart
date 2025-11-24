import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/icon_button.dart';

class WedyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WedyAppBar({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.centerTitle = true,
    this.showBackButton = false,
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final resolvedLeading = _buildLeading(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          children: [
            if (resolvedLeading != null) resolvedLeading,
            if (resolvedLeading != null) const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: _Title(
                title: title,
                center: centerTitle,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBackButton) return null;

    return WedyIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      onPressed: () => Navigator.of(context).maybePop(),
      size: 40,
      backgroundColor: AppColors.surface,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _Title extends StatelessWidget {
  const _Title({required this.title, required this.center});

  final String? title;
  final bool center;

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        title!,
        style: AppTextStyles.title1,
        textAlign: center ? TextAlign.center : TextAlign.start,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
