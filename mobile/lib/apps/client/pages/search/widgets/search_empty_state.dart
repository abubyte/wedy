part of '../search_page.dart';

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: const Icon(IconsaxPlusLinear.search_normal_1, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'Qidiruv natijalari topilmadi',
              style: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'Boshqa kalit so\'zlar bilan qidirib ko\'ring',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

