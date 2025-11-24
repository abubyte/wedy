import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

class MerchantProfilePage extends StatelessWidget {
  const MerchantProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _ProfileHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              const _SectionCard(
                title: 'Akkount',
                items: [
                  _ProfileItem(
                    icon: IconsaxPlusLinear.user,
                    label: 'Ism',
                    value: 'Sam decor',
                  ),
                  _ProfileItem(
                    icon: IconsaxPlusLinear.call,
                    label: 'Telefon raqamni almashtirish',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),
              const _SectionCard(
                title: 'Yordam',
                items: [
                  _ProfileItem(icon: IconsaxPlusLinear.message_question, label: 'Yordam'),
                  _ProfileItem(icon: IconsaxPlusLinear.document, label: 'Foydalanish shartlari / Maxfiylik siyosati'),
                  _ProfileItem(icon: IconsaxPlusLinear.like_1, label: 'Ilovani baxolash'),
                  _ProfileItem(icon: IconsaxPlusLinear.message, label: 'Fikr bildirish'),
                  _ProfileItem(icon: IconsaxPlusLinear.graph, label: 'Wedy Biznes'),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              WedyPrimaryButton(
                label: 'Akkauntdan chiqish',
                onPressed: () {},
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              IconsaxPlusLinear.user,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sam decor',
                  style: AppTextStyles.title2,
                ),
                Text(
                  'ID: 10481931',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingS),
              child: Icon(IconsaxPlusLinear.edit, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items});

  final String title;
  final List<_ProfileItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title2,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ...items.map((item) => Column(
                children: [
                  _ProfileTile(item: item),
                  if (item != items.last)
                    const Divider(
                      height: AppDimensions.spacingL,
                      color: AppColors.border,
                    ),
                ],
              )),
        ],
      ),
    );
  }
}

class _ProfileItem {
  const _ProfileItem({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.item});

  final _ProfileItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              child: Icon(
                item.icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodyRegular,
                ),
                if (item.value != null)
                  Text(
                    item.value!,
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          const Icon(
            IconsaxPlusLinear.arrow_right,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
