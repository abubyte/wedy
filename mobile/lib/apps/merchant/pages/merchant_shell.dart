import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';
import 'services/services_page.dart';
import 'chats/chats_page.dart';

class MerchantShellPage extends StatefulWidget {
  const MerchantShellPage({super.key});

  @override
  State<MerchantShellPage> createState() => _MerchantShellPageState();
}

class _MerchantShellPageState extends State<MerchantShellPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MerchantHomePage(),
    MerchantChatsPage(),
    MerchantFavoritesPage(),
    MerchantProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: AppDimensions.spacingM,
          right: AppDimensions.spacingM,
          bottom: AppDimensions.spacingS,
        ),
        child: DecoratedBox(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(IconsaxPlusLinear.home),
                  label: 'Bosh sahifa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(IconsaxPlusLinear.message),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(IconsaxPlusLinear.heart),
                  label: 'Sevimli',
                ),
                BottomNavigationBarItem(
                  icon: Icon(IconsaxPlusLinear.user),
                  label: 'Profil',
                ),
              ],
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
