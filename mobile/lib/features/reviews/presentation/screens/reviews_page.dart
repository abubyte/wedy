import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wedy/core/di/injection_container.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import '../../domain/entities/review.dart';
import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';
import 'widgets/add_review_dialog.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key, this.serviceId});

  final String? serviceId;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    if (widget.serviceId != null) {
      context.read<ReviewBloc>().add(LoadReviewsEvent(serviceId: widget.serviceId!));
    }
  }

  void _loadMore() {
    final state = context.read<ReviewBloc>().state;
    if (state is ReviewsLoaded && state.response.hasMore) {
      context.read<ReviewBloc>().add(const LoadMoreReviewsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceId = widget.serviceId ?? GoRouterState.of(context).uri.queryParameters['serviceId'];

    if (serviceId == null || serviceId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fikrlar')),
        body: const Center(child: Text('Service ID is required')),
      );
    }

    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (!_refreshController.isRefresh) return;

        if (state is ReviewsLoaded || state is ReviewError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _refreshController.isRefresh) {
              if (state is ReviewsLoaded) {
                _refreshController.refreshCompleted();
              } else {
                _refreshController.refreshFailed();
              }
            }
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
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
            child: SingleChildScrollView(
              controller: _scrollController,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
                      _loadMore();
                    }
                  }
                  return false;
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button and header
                      Row(
                        children: [
                          const WedyCircularButton(),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(
                            child: Text(
                              'Fikrlar',
                              style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 24),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddReviewDialog(context, serviceId),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Fikr qo\'shish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Reviews list
                      BlocBuilder<ReviewBloc, ReviewState>(
                        builder: (context, state) {
                          if (state is ReviewLoading || state is ReviewInitial) {
                            return const Padding(
                              padding: EdgeInsets.all(AppDimensions.spacingL),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (state is ReviewError) {
                            return Padding(
                              padding: const EdgeInsets.all(AppDimensions.spacingL),
                              child: Center(
                                child: Column(
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
                              ),
                            );
                          }

                          final reviews = state is ReviewsLoaded ? state.allReviews : <Review>[];

                          if (reviews.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(AppDimensions.spacingL),
                              child: Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Hozircha fikrlar yo\'q',
                                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingM),
                                    ElevatedButton(
                                      onPressed: () => _showAddReviewDialog(context, serviceId),
                                      child: const Text('Birinchi fikrni qo\'shing'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              ...reviews.map((review) => _ReviewCard(review: review)),
                              if (state is ReviewsLoaded && state.response.hasMore)
                                const Padding(
                                  padding: EdgeInsets.all(AppDimensions.spacingM),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, String serviceId) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<ReviewBloc>(
        create: (context) => getIt<ReviewBloc>(),
        child: AddReviewDialog(serviceId: serviceId),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final userName = review.user?.name ?? 'Foydalanuvchi';
    final avatarUrl = review.user?.avatarUrl;
    final date = _formatDate(review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
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
                width: 48,
                height: 48,
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
                          errorBuilder: (context, error, stackTrace) => const Icon(IconsaxPlusLinear.user, size: 24),
                        ),
                      )
                    : const Icon(IconsaxPlusLinear.user, size: 24),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.bodyRegular.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(IconsaxPlusBold.star_1, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toString(),
                    style: AppTextStyles.bodyRegular.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Text(review.comment!, style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textSecondary)),
          ],
        ],
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
