import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/utils/shimmer_helper.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'hot_offers_banner_widget.dart';

/// Widget that displays featured services with its own ServiceBloc
class FeaturedServicesSection extends StatefulWidget {
  const FeaturedServicesSection({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  State<FeaturedServicesSection> createState() => _FeaturedServicesSectionState();
}

class _FeaturedServicesSectionState extends State<FeaturedServicesSection> {
  bool _hasCheckedInitialLoad = false;

  @override
  Widget build(BuildContext context) {
    // Use the global ServiceBloc instance to sync state across pages
    final globalBloc = context.read<ServiceBloc>();

    // Reload if state doesn't match what we need (only check once per build cycle)
    final currentState = globalBloc.state;
    final hasFeaturedServices = currentState is UniversalServicesState
        ? currentState.featuredServices != null && currentState.featuredServices!.isNotEmpty
        : (currentState is ServicesLoaded && currentState.response.services.any((s) => s.isFeatured));

    if (!_hasCheckedInitialLoad || (!hasFeaturedServices && currentState is! ServiceLoading)) {
      _hasCheckedInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final state = globalBloc.state;
          final hasFeatured = state is UniversalServicesState
              ? state.featuredServices != null && state.featuredServices!.isNotEmpty
              : (state is ServicesLoaded && state.response.services.any((s) => s.isFeatured));
          if (!hasFeatured && state is! ServiceLoading) {
            globalBloc.add(const LoadServicesEvent(featured: true, page: 1, limit: 10));
          }
        }
      });
    }

    return BlocProvider.value(
      value: globalBloc,
      child: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          if (widget.isLoading || state is ServiceLoading || state is ServiceInitial) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
              child: _HotOffersBannerShimmer(),
            );
          }

          if (state is ServiceError) {
            return const SizedBox.shrink();
          }

          final featuredServices = state is UniversalServicesState
              ? (state.featuredServices ?? <ServiceListItem>[])
              : (state is ServicesLoaded ? state.allServices : <ServiceListItem>[]);

          if (featuredServices.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            child: HotOffersBannerWidget(services: featuredServices),
          );
        },
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
            child: Row(
              children: [
                Expanded(child: ShimmerHelper.shimmerContainer(height: 24, borderRadius: 4.0)),
                const SizedBox(width: AppDimensions.spacingM),
                ShimmerHelper.shimmerCircle(width: 24, height: 24),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
            child: ShimmerHelper.shimmerContainer(height: 14, width: 200, borderRadius: 4.0),
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
                      child: AspectRatio(aspectRatio: .7, child: ShimmerHelper.shimmerRounded(height: 211)),
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
