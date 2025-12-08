part of '../service_page.dart';

class ServiceMetaTile extends StatelessWidget {
  final String locationRegion;
  final String categoryName;

  const ServiceMetaTile({super.key, required this.locationRegion, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Region
        Text(
          locationRegion,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
        ),
        const SizedBox(width: AppDimensions.spacingXS),

        // Separator
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
        ),
        const SizedBox(width: AppDimensions.spacingXS),

        // Category
        Text(
          categoryName,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
        ),
      ],
    );
  }
}
