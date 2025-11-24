part of '../items_page.dart';

class _HotOffersMetaCard extends StatelessWidget {
  const _HotOffersMetaCard({super.key, required this.category});

  final category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: .5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL, vertical: AppDimensions.spacingS),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/ct1.png',
            height: 60,
            width: 60,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.surfaceMuted,
              alignment: Alignment.center,
              child: const Icon(IconsaxPlusLinear.image, color: AppColors.textMuted),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 65, height: 82),

              Expanded(
                child: Text(
                  category.label,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    overflow: TextOverflow.ellipsis,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
