part of '../service_page.dart';

class ServiceStatisticsCard extends StatelessWidget {
  const ServiceStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                IconsaxPlusLinear.star_1,
                size: 24,
                color: Colors.black,
              ),
              Text(
                '4.7',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
            child: Divider(color: Color(0xFFE2E8FA), height: 1),
          ),

          const SizedBox(height: AppDimensions.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(IconsaxPlusLinear.eye, size: 24, color: Colors.black),
              Text(
                '10 000',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
            child: Divider(color: Color(0xFFE2E8FA), height: 1),
          ),

          const SizedBox(height: AppDimensions.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                IconsaxPlusLinear.message,
                size: 24,
                color: Colors.black,
              ),
              Text(
                '48',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingS),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
            child: Divider(color: Color(0xFFE2E8FA), height: 1),
          ),

          const SizedBox(height: AppDimensions.spacingM),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ulashish',
                style: AppTextStyles.bodyRegular.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Icon(
                IconsaxPlusLinear.export_2,
                size: 18,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
