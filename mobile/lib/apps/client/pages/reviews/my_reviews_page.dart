import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_state.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_bloc.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_event.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_state.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();
  final Map<String, ServiceListItem> _serviceCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _fetchServiceDetails(String serviceId) {
    if (!_serviceCache.containsKey(serviceId)) {
      context.read<ServiceBloc>().add(LoadServiceByIdEvent(serviceId));
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<ReviewBloc>().add(const LoadMoreUserReviewsEvent());
    }
  }

  void _onRefresh() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ReviewBloc>().add(LoadUserReviewsEvent(userId: authState.user.id));
    }
  }

  void _deleteReview(String reviewId) {
    // Get the bloc before showing the dialog
    final reviewBloc = context.read<ReviewBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fikrni o\'chirish'),
        content: const Text('Haqiqatan ham bu fikrni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              reviewBloc.add(DeleteReviewEvent(reviewId));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (!_refreshController.isRefresh) return;

        if (state is ReviewsLoaded || state is ReviewError || state is ReviewDeleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _refreshController.isRefresh) {
              if (state is ReviewsLoaded || state is ReviewDeleted) {
                _refreshController.refreshCompleted();
              } else {
                _refreshController.refreshFailed();
              }
            }
          });
        }

        if (state is ReviewDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fikr muvaffaqiyatli o\'chirildi'), backgroundColor: AppColors.success),
          );
          // Reload reviews
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<ReviewBloc>().add(LoadUserReviewsEvent(userId: authState.user.id));
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                alignment: Alignment.centerLeft,
                child: const WedyCircularButton(),
              ),
              const SizedBox(height: AppDimensions.spacingM),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                alignment: Alignment.centerLeft,
                child: Text('Fikrlarim', style: AppTextStyles.headline2),
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // Reviews list
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    if (authState is! Authenticated) {
                      return const Center(child: Text('Kirish kerak'));
                    }

                    return BlocBuilder<ReviewBloc, ReviewState>(
                      builder: (context, state) {
                        if (state is ReviewLoading || state is ReviewInitial) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (state is ReviewError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.message,
                                  style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.spacingM),
                                ElevatedButton(onPressed: _onRefresh, child: const Text('Qayta urinish')),
                              ],
                            ),
                          );
                        }

                        final reviews = state is ReviewsLoaded ? state.allReviews : <Review>[];

                        if (reviews.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hozircha fikrlar yo\'q',
                                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        // Fetch service details for all reviews
                        for (final review in reviews) {
                          if (!_serviceCache.containsKey(review.serviceId)) {
                            _fetchServiceDetails(review.serviceId);
                          }
                        }

                        return BlocListener<ServiceBloc, ServiceState>(
                          listener: (context, serviceState) {
                            if (serviceState is UniversalServicesState && serviceState.currentServiceDetails != null) {
                              final service = serviceState.currentServiceDetails!;
                              setState(() {
                                _serviceCache[service.id] = ServiceListItem(
                                  id: service.id,
                                  name: service.name,
                                  description: service.description,
                                  price: service.price,
                                  locationRegion: service.locationRegion,
                                  overallRating: service.overallRating,
                                  totalReviews: service.totalReviews,
                                  viewCount: service.viewCount,
                                  likeCount: service.likeCount,
                                  saveCount: service.saveCount,
                                  createdAt: service.createdAt,
                                  merchant: service.merchant,
                                  categoryId: service.categoryId,
                                  categoryName: service.categoryName,
                                  mainImageUrl: service.images.isNotEmpty ? service.images.first.s3Url : null,
                                );
                              });
                            }
                          },
                          child: SmartRefresher(
                            controller: _refreshController,
                            onRefresh: _onRefresh,
                            enablePullDown: true,
                            enablePullUp: false,
                            header: const ClassicHeader(
                              refreshingText: 'Yangilanmoqda...',
                              completeText: 'Yangilandi!',
                              idleText: 'Yangilash uchun torting',
                              releaseText: 'Yangilash uchun qo\'yib yuboring',
                              textStyle: TextStyle(color: AppColors.primary),
                            ),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                              itemCount: reviews.length + (state is ReviewsLoaded && state.response.hasMore ? 1 : 0),
                              separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.spacingM),
                              itemBuilder: (context, index) {
                                if (index >= reviews.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(AppDimensions.spacingM),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                final review = reviews[index];
                                final service = _serviceCache[review.serviceId];

                                return _ReviewCard(
                                  review: review,
                                  service: service,
                                  onDelete: () => _deleteReview(review.id),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final ServiceListItem? service;
  final VoidCallback onDelete;

  const _ReviewCard({required this.review, this.service, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service info row
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: GestureDetector(
                    onTap: () => context.push('${RouteNames.serviceDetails}?id=${review.serviceId}'),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: AppColors.border,
                      child: service?.mainImageUrl != null && service!.mainImageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: service!.mainImageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(IconsaxPlusLinear.image, size: 40, color: Colors.grey),
                            )
                          : const Icon(IconsaxPlusLinear.image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                // Service details
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('${RouteNames.serviceDetails}?id=${review.serviceId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: service != null
                                    ? service!.price
                                          .toStringAsFixed(0)
                                          .replaceAllMapped(
                                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                            (Match m) => '${m[1]} ',
                                          )
                                    : 'Yuklanmoqda...',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: " so'm",
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),

                        // Service name
                        Text(
                          service?.name ?? review.service?.name ?? 'Noma\'lum xizmat',
                          style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // const SizedBox(height: AppDimensions.spacingXS),
                        // Location and category
                        Text(
                          service != null
                              ? '${service!.locationRegion} • ${service!.categoryName}'
                              : review.service?.name ?? '',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: onDelete,
                  child: Stack(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6666),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.error, width: 1),
                        ),
                      ),
                      Positioned.fill(
                        top: -4,
                        left: -4,
                        child: const Icon(IconsaxPlusLinear.trash_square, size: 32, color: AppColors.surface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // User's review/comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingM,
                0,
                AppDimensions.spacingM,
                AppDimensions.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sizning fikringiz:',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  ),
                  // const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    review.comment!,
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
