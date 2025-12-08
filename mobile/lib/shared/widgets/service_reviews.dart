import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/di/injection_container.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_bloc.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_event.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_state.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart';
import 'package:wedy/shared/navigation/route_names.dart';

class ServiceReviews extends StatelessWidget {
  const ServiceReviews({super.key, this.serviceId, this.vertical = false, this.showHeader = true});

  final String? serviceId;
  final bool vertical;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    if (serviceId == null || serviceId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (context) {
        final bloc = getIt<ReviewBloc>();
        bloc.add(LoadReviewsEvent(serviceId: serviceId!, page: 1, limit: vertical ? 20 : 5));
        return bloc;
      },
      child: BlocBuilder<ReviewBloc, ReviewState>(
        builder: (context, state) {
          final reviews = state is ReviewsLoaded ? state.allReviews : <Review>[];

          if (state is ReviewLoading || state is ReviewInitial) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingM),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ReviewError) {
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Text(
                state.message,
                style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (reviews.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Text(
                'Hozircha fikrlar yo\'q',
                style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fikrlar (${reviews.length})',
                      style: AppTextStyles.headline2,
                    ),
                    if (!vertical)
                      TextButton(
                        onPressed: () => context.pushNamed(RouteNames.reviews, queryParameters: {'serviceId': serviceId!}),
                        child: Text('Barchasini ko\'rish', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],
              SizedBox(
                height: vertical ? null : 110,
                child: ListView.separated(
                  itemCount: vertical ? reviews.length : (reviews.length > 5 ? 5 : reviews.length),
                  scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
                  shrinkWrap: vertical,
                  physics: vertical ? const NeverScrollableScrollPhysics() : null,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppDimensions.spacingS, height: AppDimensions.spacingS),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final isFirst = index == 0;
                    final isLast = index == (vertical ? reviews.length - 1 : (reviews.length > 5 ? 4 : reviews.length - 1));
                    return _ReviewCard(
                      review: review,
                      vertical: vertical,
                      isFirst: isFirst,
                      isLast: isLast,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.vertical,
    required this.isFirst,
    required this.isLast,
  });

  final Review review;
  final bool vertical;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final userName = review.user?.name ?? 'Foydalanuvchi';
    final avatarUrl = review.user?.avatarUrl;
    final date = _formatDate(review.createdAt);

    return Center(
      child: Container(
        margin: EdgeInsets.only(
          left: vertical ? 0 : (isFirst ? AppDimensions.spacingL : 0),
          right: vertical ? 0 : (isLast ? AppDimensions.spacingL : 0),
        ),
        width: vertical ? null : 300,
        padding: const EdgeInsets.all(AppDimensions.spacingSM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    color: AppColors.surfaceMuted,
                  ),
                  child: avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(IconsaxPlusLinear.user, size: 20),
                          ),
                        )
                      : const Icon(IconsaxPlusLinear.user, size: 20),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          color: const Color(0xFF3B1752),
                        ),
                      ),
                      Text(
                        date,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.star_1, size: 9, color: Colors.yellow),
                          const SizedBox(width: AppDimensions.spacingXS),
                          Text(
                            review.rating.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                review.comment!,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: const Color(0xFF9CA3AF),
                ),
                overflow: vertical ? null : TextOverflow.ellipsis,
                maxLines: vertical ? null : 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
