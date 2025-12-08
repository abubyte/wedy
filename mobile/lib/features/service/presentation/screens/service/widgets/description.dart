part of '../service_page.dart';

class ServiceDescription extends StatelessWidget {
  final String description;

  const ServiceDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border, width: .5),
      ),
      child: Text(description, style: AppTextStyles.bodyRegular.copyWith(fontSize: 12, color: const Color(0xFF9CA3AF))),
    );
  }
}
