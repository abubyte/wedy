import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/features/service/presentation/screens/service/service_page.dart';
import 'package:wedy/apps/merchant/widgets/tariff_status.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/section_header.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  final status = TariffStatus.active;
  final _statisticsBoxKey = GlobalKey();
  double? _statisticsBoxHeight;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: status == TariffStatus.active ? AppColors.border : AppColors.error,
                      width: .5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        key: _statisticsBoxKey,
                        children: [
                          Row(
                            children: [
                              Expanded(
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
                                          const Icon(IconsaxPlusLinear.eye, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          Text(
                                            '12 345',
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
                                            '+345',
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
                              ),
                              const SizedBox(width: AppDimensions.spacingS),

                              Expanded(
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
                                          const Icon(IconsaxPlusLinear.save_2, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          Text(
                                            '3 182',
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
                                            '+130',
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
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingS),

                          Row(
                            children: [
                              Expanded(
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
                                          const Icon(IconsaxPlusLinear.star_1, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          Text(
                                            '4.5',
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
                                            '+41',
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
                              ),
                              const SizedBox(width: AppDimensions.spacingS),

                              Expanded(
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
                                          const Icon(IconsaxPlusLinear.message, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          Text(
                                            '93',
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
                                            '+0',
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
                              ),
                              const SizedBox(width: AppDimensions.spacingS),

                              Expanded(
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
                                          const Icon(IconsaxPlusLinear.link_2, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          Text(
                                            '3',
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
                                            '+0',
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
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingS),

                          WedyPrimaryButton(
                            label: 'Reklama berish',
                            onPressed: () => context.push(RouteNames.boost),
                            outlined: status != TariffStatus.active,
                          ),
                        ],
                      ),
                      if (status != TariffStatus.active && _statisticsBoxHeight != null) ...[
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
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Reviews
                if (status == TariffStatus.active) ...[
                  SectionHeader(
                    title: 'Fikrlar',
                    applyPadding: true,
                    onTap: () => context.pushNamed(RouteNames.reviews),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  const ServiceReviews(),
                  const SizedBox(height: AppDimensions.spacingM),
                ],

                // Tariff Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                  child: WedyTariffStatus(status: status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
