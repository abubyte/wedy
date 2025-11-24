part of '../items_page.dart';

class _CategoryMetaCard extends StatelessWidget {
  const _CategoryMetaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 75,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFFD3E3FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Qaynoq takliflar!',
                      style: AppTextStyles.title1.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      border: Border.all(color: AppColors.primaryDark, width: .5),
                    ),
                    child: const Center(child: Icon(IconsaxPlusLinear.lamp_on, color: AppColors.textInverse, size: 12)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
              child: Text(
                'Eng yaxshi xizmat va mahsulotlar shu yerda.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textInverse,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
          ],
        ),
      ),
    );
  }
}
