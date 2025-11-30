import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

enum TariffStatus { active, expired, notSelected }

class WedyTariffStatus extends StatelessWidget {
  final TariffStatus status;
  final bool settingsPage;

  const WedyTariffStatus({super.key, this.settingsPage = false, required this.status});

  @override
  Widget build(BuildContext context) {
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
            color: status == TariffStatus.active || settingsPage ? AppColors.border : AppColors.error,
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
                Text(
                  switch (status) {
                    TariffStatus.active => 'Start',
                    TariffStatus.expired => 'Start',
                    TariffStatus.notSelected => 'Tanlanmagan',
                  },
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: status == TariffStatus.active || status == TariffStatus.expired
                        ? Colors.black
                        : AppColors.textError,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            const Divider(color: AppColors.border, thickness: .5),
            const SizedBox(height: AppDimensions.spacingS),
            if (!(settingsPage && status == TariffStatus.notSelected)) ...[
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
                    switch (status) {
                      TariffStatus.active => '23-Avgustgacha',
                      TariffStatus.expired => 'Tarif muddati tugadi',
                      TariffStatus.notSelected => 'Tanlanmagan',
                    },
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: status == TariffStatus.active ? AppColors.primary : AppColors.textError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              if (status != TariffStatus.active) const Divider(color: AppColors.border, thickness: .5),
              const SizedBox(height: AppDimensions.spacingS),
            ],

            if (status != TariffStatus.active) ...[
              WedyPrimaryButton(
                label: status == TariffStatus.expired ? 'To\'lash' : 'Tarif tanlash',
                onPressed: () => context.pushNamed(RouteNames.tariff),
              ),
              const SizedBox(height: AppDimensions.spacingS),
            ],

            if (status == TariffStatus.expired) ...[
              WedyPrimaryButton(label: "Boshqa tarifga o'zgartirish", onPressed: () {}, outlined: true),
              const SizedBox(height: AppDimensions.spacingS),
            ],
          ],
        ),
      ),
    );
  }
}
