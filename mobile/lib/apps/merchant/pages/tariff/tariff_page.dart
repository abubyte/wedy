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
            if (state is TariffDataLoaded) {
              plans = state.plans;
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

                  // Tariff plans
                  if (plans.isNotEmpty) ...[...plans.map((plan) => _buildTariffCard(context, plan))],

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

  Widget _buildTariffCard(BuildContext context, TariffPlan plan) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: 1),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          WedyPrimaryButton(label: 'Tarifni faollashtirish', onPressed: () => _navigateToDuration(context, plan)),
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
