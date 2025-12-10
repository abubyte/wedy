import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/di/injection_container.dart' as di;
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/tariff/domain/entities/tariff.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_bloc.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_event.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_state.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class TariffPage extends StatelessWidget {
  const TariffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = di.getIt<TariffBloc>();
        bloc.add(const LoadTariffPlansEvent());
        bloc.add(const LoadSubscriptionEvent());
        return bloc;
      },
      child: const _TariffPageContent(),
    );
  }
}

class _TariffPageContent extends StatefulWidget {
  const _TariffPageContent();

  @override
  State<_TariffPageContent> createState() => _TariffPageContentState();
}

class _TariffPageContentState extends State<_TariffPageContent> {
  TariffPlan? selectedPlan;
  int selectedDuration = 1; // 1, 3, 6, or 12 months
  final List<int> durations = [1, 3, 6, 12];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tariflar', style: AppTextStyles.headline2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: BlocConsumer<TariffBloc, TariffState>(
        listener: (context, state) {
          if (state is PaymentCreated) {
            // Open payment URL if available
            if (state.payment.paymentUrl != null) {
              _launchPaymentUrl(state.payment.paymentUrl!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('To\'lov yaratildi. Tekshirilmoqda...'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Refresh subscription
              context.read<TariffBloc>().add(const RefreshTariffEvent());
            }
          } else if (state is TariffError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          // Handle initial loading state
          if (state is TariffLoading &&
              state is! TariffPlansLoaded &&
              state is! SubscriptionLoaded &&
              state is! TariffDataLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current subscription card
                BlocBuilder<TariffBloc, TariffState>(
                  builder: (context, state) {
                    Subscription? sub;
                    if (state is TariffDataLoaded) {
                      sub = state.subscription;
                    } else if (state is SubscriptionLoaded) {
                      sub = state.subscription;
                    }
                    if (sub != null) {
                      return Column(
                        children: [
                          _buildCurrentSubscriptionCard(sub),
                          const SizedBox(height: AppDimensions.spacingL),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Tariff plans
                Text('Mavjud tariflar', style: AppTextStyles.title1),
                const SizedBox(height: AppDimensions.spacingM),
                BlocBuilder<TariffBloc, TariffState>(
                  builder: (context, state) {
                    List<TariffPlan> plansList = [];
                    if (state is TariffDataLoaded) {
                      plansList = state.plans;
                    } else if (state is TariffPlansLoaded) {
                      plansList = state.plans;
                    }
                    if (plansList.isNotEmpty) {
                      return Column(children: plansList.map((plan) => _buildTariffPlanCard(plan)).toList());
                    }
                    if (state is TariffLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(AppDimensions.spacingL),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: AppDimensions.spacingL),

                // Duration selector
                if (selectedPlan != null) ...[
                  Text('Muddat', style: AppTextStyles.title1),
                  const SizedBox(height: AppDimensions.spacingM),
                  Row(
                    children: durations.map((duration) {
                      final isSelected = selectedDuration == duration;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedDuration = duration),
                          child: Container(
                            margin: EdgeInsets.only(right: duration != durations.last ? AppDimensions.spacingS : 0),
                            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                '$duration oy',
                                style: AppTextStyles.bodyRegular.copyWith(
                                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Total price
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jami:', style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${NumberFormat('#,###').format(selectedPlan!.pricePerMonth * selectedDuration)} so\'m',
                          style: AppTextStyles.title1.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Purchase button
                  WedyPrimaryButton(
                    label: 'To\'lash',
                    onPressed: () {
                      context.read<TariffBloc>().add(
                        CreateTariffPaymentEvent(
                          tariffPlanId: selectedPlan!.id,
                          durationMonths: selectedDuration,
                          paymentMethod: 'payme', // Default payment method
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(Subscription subscription) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: subscription.isActive ? AppColors.primary : AppColors.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Joriy tarif',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: 4),
                decoration: BoxDecoration(
                  color: subscription.isActive ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  subscription.isActive ? 'Faol' : 'Tugagan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(subscription.tariffPlan.name, style: AppTextStyles.title1),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            '${dateFormat.format(subscription.startDate)} - ${dateFormat.format(subscription.endDate)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          if (subscription.isActive) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              'Qolgan: ${subscription.daysRemaining} kun',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTariffPlanCard(TariffPlan plan) {
    final isSelected = selectedPlan?.id == plan.id;
    return GestureDetector(
      onTap: () => setState(() => selectedPlan = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.name, style: AppTextStyles.title1),
                if (isSelected) const Icon(IconsaxPlusLinear.tick_circle, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              '${NumberFormat('#,###').format(plan.pricePerMonth)} so\'m/oy',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildFeatureRow('Xizmatlar', plan.maxServices.toString()),
            _buildFeatureRow('Rasmlar/xizmat', plan.maxImagesPerService.toString()),
            _buildFeatureRow('Telefon raqamlari', plan.maxPhoneNumbers.toString()),
            _buildFeatureRow('Galereya rasmlari', plan.maxGalleryImages.toString()),
            _buildFeatureRow('Ijtimoiy tarmoqlar', plan.maxSocialAccounts.toString()),
            if (plan.allowWebsite) _buildFeatureRow('Veb-sayt', 'Mavjud'),
            if (plan.allowCoverImage) _buildFeatureRow('Cover rasm', 'Mavjud'),
            if (plan.monthlyFeaturedCards > 0)
              _buildFeatureRow('Reklama kartalar', plan.monthlyFeaturedCards.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
