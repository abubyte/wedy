part of '../favorites_page.dart';

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 63,
              height: 63,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: const Icon(IconsaxPlusLinear.heart_search, color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text('Sevimli elonlaringiz yo\'q', style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
