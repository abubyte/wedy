import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/apps/client/pages/home/blocs/featured_services/featured_services_bloc.dart';
import 'package:wedy/apps/client/pages/home/blocs/featured_services/featured_services_state.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/utils/shimmer_helper.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'hot_offers_banner_widget.dart';

class FeaturedServicesSection extends StatelessWidget {
  const FeaturedServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeaturedServicesBloc, FeaturedServicesState>(
      builder: (context, state) {
        if (state.status == StateStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            child: _HotOffersBannerShimmer(),
          );
        }

        if (state.status == StateStatus.error) {
          return const SizedBox.shrink();
        }

        final featuredServices = state.status == StateStatus.loaded
            ? state.data
            : <ServiceListItem>[];

        if (featuredServices.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
          ),
          child: HotOffersBannerWidget(services: featuredServices),
        );
      },
    );
  }
}

/// Shimmer widget for hot offers banner
class _HotOffersBannerShimmer extends StatelessWidget {
  const _HotOffersBannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ShimmerHelper.shimmerContainer(
                    height: 24,
                    borderRadius: 4.0,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                ShimmerHelper.shimmerCircle(width: 24, height: 24),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
            ),
            child: ShimmerHelper.shimmerContainer(
              height: 14,
              width: 200,
              borderRadius: 4.0,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
            child: SizedBox(
              height: 211,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: 3,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: AppDimensions.spacingS);
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? AppDimensions.spacingS : 0,
                        right: index == 2 ? AppDimensions.spacingS : 0,
                      ),
                      child: AspectRatio(
                        aspectRatio: .7,
                        child: ShimmerHelper.shimmerRounded(height: 211),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
