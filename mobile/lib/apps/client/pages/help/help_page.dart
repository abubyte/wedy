import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    // if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    // }
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://t.me/wedysupportbot');
    // if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/998886116165');
    // if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse('https://wedy.uz');
    // if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

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
                child: Text('Yordam', style: AppTextStyles.headline2),
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
                      onTap: () => _makePhoneCall('+998886116165'),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.call_calling, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            '+998 88 611 61 65',
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
                      onTap: () => _makePhoneCall('+998886116165'),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.call_calling, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            '+998 88 611 61 65',
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
                      onTap: () => _openTelegram(),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.send_2, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'Telegram',
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
                      onTap: () => _openWhatsApp(),
                      child: Row(
                        children: [
                          const Icon(IconsaxPlusLinear.message, size: 24, color: Colors.black),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'WhatsApp',
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

              GestureDetector(
                onTap: () => _openWebsite(),
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
                      const Icon(IconsaxPlusLinear.global, size: 24, color: Colors.black),
                      const SizedBox(width: AppDimensions.spacingM),
                      Text(
                        'wedy.uz',
                        style: AppTextStyles.bodyRegular.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                    ],
                  ),
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
