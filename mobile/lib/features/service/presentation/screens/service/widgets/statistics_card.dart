part of '../service_page.dart';

class ServiceStatisticsCard extends StatelessWidget {
  final int viewCount;
  final int likeCount;
  final int saveCount;
  final int shareCount;
  final double rating;
  final int reviewCount;

  const ServiceStatisticsCard({
    super.key,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    required this.shareCount,
    required this.rating,
    required this.reviewCount,
  });

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: .5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(IconsaxPlusLinear.star_1, size: 24, color: Colors.black),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
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
                _formatNumber(viewCount),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
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
              const Icon(IconsaxPlusLinear.message, size: 24, color: Colors.black),
              Text(
                _formatNumber(reviewCount),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
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
              const Icon(IconsaxPlusLinear.export_2, size: 18, color: Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }
}
