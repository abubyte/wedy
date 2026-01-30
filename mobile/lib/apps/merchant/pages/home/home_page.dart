import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:wedy/apps/merchant/widgets/tariff_status.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/di/injection_container.dart' as di;
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/analytics/domain/entities/analytics.dart';
import 'package:wedy/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:wedy/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:wedy/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_bloc.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_state.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_bloc.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_event.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/primary_button.dart';
import 'package:wedy/shared/widgets/section_header.dart';
import 'package:wedy/shared/widgets/service_reviews.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  final _statisticsBoxKey = GlobalKey();
  double? _statisticsBoxHeight;
  final _numberFormat = NumberFormat('#,###', 'uz_UZ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _statisticsBoxKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          _statisticsBoxHeight = renderBox.size.height;
        });
      }
    });
  }

  String _formatNumber(int number) {
    return _numberFormat.format(number).replaceAll(',', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.getIt<TariffBloc>()..add(const LoadSubscriptionEvent())),
        BlocProvider(create: (context) => di.getIt<AnalyticsBloc>()..add(const LoadAnalyticsEvent())),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<TariffBloc>().add(const LoadSubscriptionEvent());
              context.read<AnalyticsBloc>().add(const RefreshAnalyticsEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                      child: Text(
                        'Bosh sahifa',
                        style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Image
                    Container(
                      width: double.infinity,
                      height: 150,
                      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        image: const DecorationImage(
                          image: NetworkImage('https://picsum.photos/300/150'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Statistics
                    BlocBuilder<TariffBloc, TariffState>(
                      builder: (context, tariffState) {
                        final subscription = tariffState is SubscriptionLoaded ? tariffState.subscription : null;
                        final isActive = subscription?.isActive ?? false;

                        return BlocBuilder<AnalyticsBloc, AnalyticsState>(
                          builder: (context, analyticsState) {
                            // Get analytics data or use defaults
                            MerchantAnalytics? analytics;
                            if (analyticsState is AnalyticsLoaded) {
                              analytics = analyticsState.analytics;
                            } else if (analyticsState is AnalyticsLoading && analyticsState.previousData != null) {
                              analytics = analyticsState.previousData;
                            } else if (analyticsState is AnalyticsError && analyticsState.previousData != null) {
                              analytics = analyticsState.previousData;
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.spacingS),
                              margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                border: Border.all(color: isActive ? AppColors.border : AppColors.error, width: .5),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    key: _statisticsBoxKey,
                                    children: [
                                      Row(
                                        children: [
                                          _buildStatCard(
                                            icon: IconsaxPlusLinear.eye,
                                            total: _formatNumber(analytics?.totalViews ?? 0),
                                            today: '+${analytics?.viewsToday ?? 0}',
                                          ),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          _buildStatCard(
                                            icon: IconsaxPlusLinear.save_2,
                                            total: _formatNumber(analytics?.totalSaves ?? 0),
                                            today: '+${analytics?.savesToday ?? 0}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppDimensions.spacingS),
                                      Row(
                                        children: [
                                          _buildStatCard(
                                            icon: IconsaxPlusLinear.star_1,
                                            total: (analytics?.overallRating ?? 0).toStringAsFixed(1),
                                            today: '+${analytics?.totalReviews ?? 0}',
                                          ),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          _buildStatCard(
                                            icon: IconsaxPlusLinear.heart,
                                            total: _formatNumber(analytics?.totalLikes ?? 0),
                                            today: '+${analytics?.likesToday ?? 0}',
                                          ),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          _buildStatCard(
                                            icon: IconsaxPlusLinear.share,
                                            total: _formatNumber(analytics?.totalShares ?? 0),
                                            today: '+${analytics?.sharesToday ?? 0}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppDimensions.spacingS),
                                      BlocBuilder<TariffBloc, TariffState>(
                                        builder: (context, state) {
                                          final subscription = state is SubscriptionLoaded ? state.subscription : null;
                                          final isActive = subscription?.isActive ?? false;
                                          return WedyPrimaryButton(
                                            label: 'Reklama berish',
                                            onPressed: () => context.push(RouteNames.boost),
                                            outlined: !isActive,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  // Overlay when tariff is inactive
                                  if (!isActive && _statisticsBoxHeight != null)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: _statisticsBoxHeight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Tarif faol emas',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textError,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Reviews
                    BlocBuilder<TariffBloc, TariffState>(
                      builder: (context, state) {
                        final subscription = state is SubscriptionLoaded ? state.subscription : null;
                        final isActive = subscription?.isActive ?? false;
                        if (isActive) {
                          return Column(
                            children: [
                              if (di.getIt<ReviewBloc>().state is ReviewsLoaded &&
                                  (di.getIt<ReviewBloc>().state as ReviewsLoaded).allReviews.isNotEmpty) ...[
                                SectionHeader(
                                  title: 'Fikrlar',
                                  applyPadding: true,
                                  onTap: () => context.pushNamed(RouteNames.reviews),
                                ),
                                const SizedBox(height: AppDimensions.spacingSM),
                                const ServiceReviews(),
                                const SizedBox(height: AppDimensions.spacingM),
                              ],
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Tariff Status
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                      child: WedyTariffStatus(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String total, required String today}) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Colors.black),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  total,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Text(
                  'Bugun:',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  today,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
