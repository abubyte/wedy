import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            children: [
              // Header
              Container(
                alignment: Alignment.centerLeft,
                child: GestureDetector(onTap: () => context.pop(), child: const WedyCircularButton()),
              ),
              const SizedBox(height: AppDimensions.spacingM),

              Container(
                alignment: Alignment.centerLeft,
                child: Text('Foydalanish shartlari / Maxfiylik siyosati', style: AppTextStyles.headline2),
              ),
              const SizedBox(height: AppDimensions.spacingM),

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
                      onTap: () => launchUrl(Uri.parse('https://wedy.uz/foydalanish-shartlari')),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.document_text_1, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'Foydalanish shartlari',
                            style: AppTextStyles.bodyRegular.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
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
                      onTap: () => launchUrl(Uri.parse('https://wedy.uz/maxfiylik-siyosati')),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.shield_tick, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'Maxfiylik siyosati',
                            style: AppTextStyles.bodyRegular.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
            ],
          ),
        ),
      ),
    );
  }
}
