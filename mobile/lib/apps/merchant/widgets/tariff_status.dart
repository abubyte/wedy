import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/di/injection_container.dart' as di;
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/tariff/domain/entities/tariff.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_bloc.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_event.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class WedyTariffStatus extends StatelessWidget {
  final bool settingsPage;

  const WedyTariffStatus({super.key, this.settingsPage = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.getIt<TariffBloc>()..add(const LoadSubscriptionEvent()),
      child: BlocBuilder<TariffBloc, TariffState>(
        builder: (context, state) {
          Subscription? subscription;
          bool isLoading = false;

          if (state is SubscriptionLoaded) {
            subscription = state.subscription;
          } else if (state is TariffLoading) {
            isLoading = true;
          }

          final hasSubscription = subscription != null;
          final isActive = subscription?.isActive ?? false;
          final isExpired = subscription?.isExpired ?? false;
          final hasNoSubscription = !hasSubscription && !isLoading;

          return InkWell(
            onTap: () => context.pushNamed(RouteNames.tariff),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: AppDimensions.spacingM,
                left: AppDimensions.spacingM,
                right: AppDimensions.spacingM,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(
                  color: (isActive || settingsPage) && !hasNoSubscription ? AppColors.border : AppColors.error,
                  width: .5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tarif:',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Text(
                          subscription?.tariffPlan.name ?? 'Tanlanmagan',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: hasNoSubscription ? AppColors.textError : Colors.black,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  const Divider(color: AppColors.border, thickness: .5),
                  const SizedBox(height: AppDimensions.spacingS),
                  if (!(settingsPage && hasNoSubscription) && !isLoading) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Faol:',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _getStatusText(subscription),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isActive ? AppColors.primary : AppColors.textError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    if (!isActive) const Divider(color: AppColors.border, thickness: .5),
                    const SizedBox(height: AppDimensions.spacingS),
                  ],

                  if (!isActive && !isLoading) ...[
                    WedyPrimaryButton(
                      label: isExpired ? 'To\'lash' : 'Tarif tanlash',
                      onPressed: () => context.pushNamed(RouteNames.tariff),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                  ],

                  if (isExpired && !isLoading) ...[
                    WedyPrimaryButton(
                      label: "Boshqa tarifga o'zgartirish",
                      onPressed: () => context.pushNamed(RouteNames.tariff),
                      outlined: true,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(Subscription? subscription) {
    if (subscription == null) {
      return 'Tanlanmagan';
    }

    if (subscription.isExpired) {
      return 'Tarif muddati tugadi';
    }

    if (subscription.isActive) {
      final dateFormat = DateFormat('dd-MMM', 'uz');
      return '${dateFormat.format(subscription.endDate)}gacha';
    }

    return 'Noma\'lum';
  }
}
