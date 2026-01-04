part of '../home_page.dart';

/// Shimmer placeholder for category services section (shown when categories are loading)
class _CategoryServicesShimmerPlaceholder extends StatelessWidget {
  const _CategoryServicesShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Header shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerHelper.shimmerContainer(
                height: 20,
                width: 120,
                borderRadius: 4.0,
              ),
              ShimmerHelper.shimmerContainer(
                height: 16,
                width: 60,
                borderRadius: 4.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // Services shimmer
        SizedBox(
          height: 211,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, serviceIndex) {
              return SizedBox(width: 150, child: ShimmerHelper.shimmerRounded(height: 211));
            },
            separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.spacingS),
            itemCount: 3, // Show 3 shimmer items
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
      ],
    );
  }
}

