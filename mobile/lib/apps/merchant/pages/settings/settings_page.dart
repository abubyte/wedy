import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/apps/merchant/widgets/tariff_status.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';

class MerchantSettingsPage extends StatelessWidget {
  const MerchantSettingsPage({super.key});

  final bool tariffActive = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Navigate to auth screen when logged out
          if (context.mounted) {
            context.go(RouteNames.auth);
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isLoggedIn = authState is Authenticated;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Text('Sozlamalar', style: AppTextStyles.headline2)],
                    ),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Tariff section
                    if (isLoggedIn) ...[
                      tariffActive
                          ? const WedyTariffStatus(settingsPage: true)
                          : GestureDetector(
                              onTap: () => context.pushNamed(RouteNames.tariff),
                              child: Container(
                                height: 43,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                  border: Border.all(color: const Color(0xFF1E4ED8), width: .5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacingM,
                                  vertical: AppDimensions.spacingS,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(IconsaxPlusLinear.document, color: AppColors.surface, size: 24),
                                    const SizedBox(width: AppDimensions.spacingM),
                                    Expanded(
                                      child: Text(
                                        'Tarif tanlash',
                                        style: AppTextStyles.bodyRegular.copyWith(color: AppColors.surface),
                                      ),
                                    ),
                                    const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.surface, size: 16),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: AppDimensions.spacingM),
                    ],

                    // Login button if not logged in
                    if (!isLoggedIn) ...[
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteNames.auth),
                        child: Container(
                          height: 43,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            border: Border.all(color: const Color(0xFF1E4ED8), width: .5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(IconsaxPlusLinear.profile, color: AppColors.surface, size: 24),
                              const SizedBox(width: AppDimensions.spacingM),
                              Expanded(
                                child: Text(
                                  'Kirish',
                                  style: AppTextStyles.bodyRegular.copyWith(color: AppColors.surface),
                                ),
                              ),
                              const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.surface, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                    ],

                    // Account Button (only when logged in)
                    if (isLoggedIn) ...[
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteNames.account),
                        child: Container(
                          height: 43,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            border: Border.all(color: AppColors.border, width: .5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          child: Row(
                            children: [
                              const Icon(IconsaxPlusLinear.profile, size: 24, color: Colors.black),
                              const SizedBox(width: AppDimensions.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Akkount',
                                      style: AppTextStyles.bodyRegular.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                    ],

                    // Profile items
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(color: AppColors.border, width: .5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                        vertical: AppDimensions.spacingS,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppDimensions.spacingXS),
                          GestureDetector(
                            onTap: () => context.push(RouteNames.tariff),
                            child: Row(
                              children: [
                                const Icon(IconsaxPlusLinear.crown_1, size: 24, color: Colors.black),
                                const SizedBox(width: AppDimensions.spacingM),
                                Text(
                                  'Tariflar',
                                  style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const Spacer(),
                                const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          GestureDetector(
                            onTap: () => context.push(RouteNames.boost),
                            child: Row(
                              children: [
                                Icon(
                                  IconsaxPlusLinear.favorite_chart,
                                  size: 24,
                                  color: tariffActive ? Colors.black : AppColors.textMuted,
                                ),
                                const SizedBox(width: AppDimensions.spacingM),
                                Text(
                                  'Reklama',
                                  style: AppTextStyles.bodyRegular.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: tariffActive ? Colors.black : AppColors.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  IconsaxPlusLinear.arrow_right_3,
                                  size: 16,
                                  color: tariffActive ? Colors.black : AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingXS),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Help items
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(color: AppColors.border, width: .5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                        vertical: AppDimensions.spacingS,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppDimensions.spacingXS),
                          Row(
                            children: [
                              const Icon(IconsaxPlusLinear.message_question, size: 24, color: Colors.black),
                              const SizedBox(width: AppDimensions.spacingM),
                              Text(
                                'Yordam',
                                style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          Row(
                            children: [
                              const Icon(IconsaxPlusLinear.document_text_1, size: 24, color: Colors.black),
                              const SizedBox(width: AppDimensions.spacingM),
                              Text(
                                'Foydalanish shartlari / Maxfiylik siyosati',
                                style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          Row(
                            children: [
                              const Icon(IconsaxPlusLinear.like_tag, size: 24, color: Colors.black),
                              const SizedBox(width: AppDimensions.spacingM),
                              Text(
                                'Ilovani baxolash',
                                style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          Row(
                            children: [
                              const Icon(IconsaxPlusLinear.sms_tracking, size: 24, color: Colors.black),
                              const SizedBox(width: AppDimensions.spacingM),
                              Text(
                                'Fikr bildirish',
                                style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingXS),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Wedy Button
                    Container(
                      height: 43,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(color: AppColors.border, width: .5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                        vertical: AppDimensions.spacingS,
                      ),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.home_1, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'Wedy',
                            style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Spacer(),
                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
