import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import '../../../widgets/service_card.dart';

/// Widget that displays featured services in a banner
class HotOffersBannerWidget extends StatelessWidget {
  const HotOffersBannerWidget({super.key, required this.services});

  final List<ServiceListItem> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        context.pushNamed(RouteNames.hotOffers);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFFD3E3FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  Expanded(
                    child: Text(
                      'Qaynoq takliflar!',
                      style: AppTextStyles.title1.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      border: Border.all(color: AppColors.primaryDark, width: .5),
                    ),
                    child: const Center(
                      child: Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.textInverse, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
              child: Text(
                'Eng yaxshi xizmat va mahsulotlar shu yerda.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textInverse,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
                  itemCount: services.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: AppDimensions.spacingS);
                  },
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? AppDimensions.spacingS : 0,
                          right: index == services.length - 1 ? AppDimensions.spacingS : 0,
                        ),
                        child: AspectRatio(
                          aspectRatio: .7,
                          child: ClientServiceCard(
                            imageUrl: service.mainImageUrl ?? '',
                            title: service.name,
                            price: service.price.toStringAsFixed(0),
                            location: service.locationRegion,
                            category: service.categoryName,
                            rating: service.overallRating,
                            isFavorite: service.isLiked,
                            onTap: () => context.push('${RouteNames.serviceDetails}?id=${service.id}'),
                            onFavoriteTap: () => context.read<ServiceBloc>().add(
                              InteractWithServiceEvent(serviceId: service.id, interactionType: 'like'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
