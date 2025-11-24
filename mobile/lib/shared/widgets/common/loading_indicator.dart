import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class WedyLoadingIndicator extends StatelessWidget {
  const WedyLoadingIndicator({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
