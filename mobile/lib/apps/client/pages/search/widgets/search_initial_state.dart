part of '../search_page.dart';

class _SearchInitialState extends StatelessWidget {
  const _SearchInitialState();

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
              child: const Icon(IconsaxPlusLinear.search_normal_1, color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Qidirish', style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'Qidirish uchun kalit so\'z kiriting',
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
