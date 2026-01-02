part of '../search_page.dart';

class _CategoryMetaCard extends StatelessWidget {
  const _CategoryMetaCard({this.category});

  final ServiceCategory? category;

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
          if (category?.iconUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: Image.network(
                category!.iconUrl!,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(IconsaxPlusLinear.image, color: AppColors.textMuted),
                ),
              ),
            )
          else
            Container(
              height: 60,
              width: 60,
              color: AppColors.surfaceMuted,
              alignment: Alignment.center,
              child: const Icon(IconsaxPlusLinear.category, color: AppColors.textMuted),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 65, height: 82),
              Expanded(
                child: Text(
                  category?.name ?? 'Kategoriya',
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
