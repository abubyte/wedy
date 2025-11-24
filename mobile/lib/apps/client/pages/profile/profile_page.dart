import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  final bool loggedIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!loggedIn) ...[
                // Header
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text('Profil', style: AppTextStyles.headline2)],
                ),
                const SizedBox(height: AppDimensions.spacingL),

                // Login button
                Container(
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
                      const Icon(
                        IconsaxPlusLinear.profile,
                        color: AppColors.surface,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Text(
                          'Kirish',
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                      const Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        color: AppColors.surface,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],

              // Account Button
              if (loggedIn) ...[
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusPill,
                        ),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
                      ),
                      child: const Icon(
                        IconsaxPlusLinear.profile,
                        size: 70,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusPill,
                          ),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: .5,
                          ),
                        ),
                        child: const Icon(
                          IconsaxPlusLinear.edit_2,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),

                Text(
                  'Sam decor',
                  style: AppTextStyles.title2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'ID: 10481931',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingM),

                Container(
                  height: 43,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingS,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.profile,
                        size: 24,
                        color: Colors.black,
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      Text(
                        'Akkount',
                        style: AppTextStyles.bodyRegular.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        size: 16,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Profile items
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
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
                          const Icon(
                            IconsaxPlusLinear.message_question,
                            size: 24,
                            color: Colors.black,
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'Fikrlar',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            IconsaxPlusLinear.arrow_right_3,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                        ),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusLinear.heart,
                            size: 24,
                            color: Colors.black,
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Text(
                            'Sevimlilar',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            IconsaxPlusLinear.arrow_right_3,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],

              // Help items
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
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
                        const Icon(
                          IconsaxPlusLinear.message_question,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Text(
                          'Yordam',
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                      ),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.document_text_1,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Text(
                          'Foydalanish shartlari / Maxfiylik siyosati',
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                      ),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.like_tag,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Text(
                          'Ilovani baxolash',
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                      ),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.sms_tracking,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Text(
                          'Fikr bildirish',
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // Wedy Biznes Button
              Container(
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                child: Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.status_up,
                      size: 24,
                      color: Colors.black,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Text(
                      'Wedy Biznes',
                      style: AppTextStyles.bodyRegular.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 16,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
            ],
          ),
        ),
      ),
    );
  }
}
