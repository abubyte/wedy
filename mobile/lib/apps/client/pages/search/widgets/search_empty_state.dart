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
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: const Icon(IconsaxPlusLinear.microscope, color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Hech narsa topilmadi', style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'Boshqa kalit so\'zlar bilan qidirib ko\'ring',
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
