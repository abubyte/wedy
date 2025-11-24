part of '../service_page.dart';

class ServiceMetaTile extends StatelessWidget {
  const ServiceMetaTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Region
        Text(
          "Qoraqalpog'iston",
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
          'Dekoratsiya',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
        ),
      ],
    );
  }
}
