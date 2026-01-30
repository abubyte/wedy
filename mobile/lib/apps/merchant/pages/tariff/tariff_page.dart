import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/apps/merchant/pages/tariff/tariff_duration_page.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/di/injection_container.dart' as di;
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/tariff/domain/entities/tariff.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_bloc.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_event.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_state.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
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

class _TariffPageContent extends StatelessWidget {
  const _TariffPageContent();

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<TariffBloc, TariffState>(
          builder: (context, state) {
            if (state is TariffLoading && state is! TariffDataLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            List<TariffPlan> plans = [];
            Subscription? subscription;
            if (state is TariffDataLoaded) {
              plans = state.plans;
              subscription = state.subscription;
            } else if (state is TariffPlansLoaded) {
              plans = state.plans;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  const WedyCircularButton(isPrimary: true),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Title
                  Text('Tariflar', style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 24)),
                  const SizedBox(height: AppDimensions.spacingXL),

                  // Current subscription info
                  if (subscription != null && subscription.isActive) _buildCurrentSubscription(subscription),

                  // Tariff plans
                  if (plans.isNotEmpty) ...[...plans.map((plan) => _buildTariffCard(context, plan, subscription))],

                  // Pro plan coming soon
                  _buildComingSoonCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentSubscription(Subscription subscription) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.success, width: 2),
        color: AppColors.success.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'Joriy tarif',
                style: AppTextStyles.bodyRegular.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            subscription.tariffPlan.name,
            style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'Tugash sanasi: ${subscription.endDate.day}/${subscription.endDate.month}/${subscription.endDate.year}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          Text(
            'Qolgan kunlar: ${subscription.daysRemaining} kun',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'Faqat yuqoriroq tarifga o\'tish mumkin.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffCard(BuildContext context, TariffPlan plan, Subscription? subscription) {
    // Check if this is the current plan
    final isCurrentPlan = subscription != null && subscription.isActive && subscription.tariffPlan.id == plan.id;

    // Check if upgrade is allowed (only higher priced plans)
    final canUpgrade =
        subscription == null || !subscription.isActive || plan.pricePerMonth > subscription.tariffPlan.pricePerMonth;

    // Check if this is a downgrade (not allowed)
    final isDowngrade =
        subscription != null && subscription.isActive && plan.pricePerMonth < subscription.tariffPlan.pricePerMonth;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: isCurrentPlan ? AppColors.primary : AppColors.border, width: isCurrentPlan ? 2 : 1),
        color: isCurrentPlan ? AppColors.primaryLight : AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current plan badge
          if (isCurrentPlan)
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text('Joriy tarif', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 10)),
            ),

          // Plan name
          Text(
            plan.name,
            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.spacingS),

          // Price
          Text(
            '${_formatPrice(plan.pricePerMonth)} so\'m/oy',
            style: AppTextStyles.headline1.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // Features list
          _buildFeatureItem('Logo, nom va tafsif', true),
          _buildFeatureItem('Narx', true),
          _buildFeatureItem('${plan.maxImagesPerService} tagacha rasm', true),
          _buildFeatureItem('Manzil', true),
          _buildFeatureItem('Telefon raqamlar qo\'shish', plan.maxPhoneNumbers > 0),
          _buildFeatureItem('Ijtimoiy tarmoqlar qo\'shish', plan.maxSocialAccounts > 0),
          _buildFeatureItem('Ijtimoiy tarmoqlar yoiq', false),
          _buildFeatureItem('Reklama yoiq', plan.monthlyFeaturedCards == 0),

          const SizedBox(height: AppDimensions.spacingL),

          // Activate button
          if (isCurrentPlan)
            const WedyPrimaryButton(label: 'Joriy tarif', outlined: true, onPressed: null)
          else if (isDowngrade)
            const WedyPrimaryButton(label: 'Pastroq tarifga o\'tish mumkin emas', outlined: true, onPressed: null)
          else if (canUpgrade)
            WedyPrimaryButton(
              label: subscription != null && subscription.isActive ? 'Tarifni yangilash' : 'Tarifni faollashtirish',
              onPressed: () => _navigateToDuration(context, plan),
            )
          else
            const WedyPrimaryButton(label: 'Tarifni faollashtirish', onPressed: null),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.cancel,
            color: isIncluded ? AppColors.primary : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyRegular.copyWith(
                color: isIncluded ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: 1),
        color: AppColors.surfaceMuted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan name
          Text(
            'Pro',
            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.spacingS),

          // Coming soon
          Text('Tez kuna...', style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: AppDimensions.spacingL),

          // Pro features preview
          _buildFeatureItem('Logo, nom va tafsif', true),
          _buildFeatureItem('10 tagacha xizmat joylash', true),
          _buildFeatureItem('Har bir xizmarga 3 ta rasm', true),
          _buildFeatureItem('Manzil + 3 ta telefon raqam', true),
          _buildFeatureItem('Profilga 3 ta rasm', true),
          _buildFeatureItem('Ijtimoiy tarmoqlar qo\'shish', true),
          _buildFeatureItem('Muqova rasmi yuklash', true),

          const SizedBox(height: AppDimensions.spacingL),

          // Disabled button
          const WedyPrimaryButton(label: 'Bu Tarif tez kunda qo\'shiladi', outlined: true, onPressed: null),
        ],
      ),
    );
  }

  void _navigateToDuration(BuildContext context, TariffPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TariffBloc>(),
          child: TariffDurationPage(tariffPlan: plan),
        ),
      ),
    );
  }
}
