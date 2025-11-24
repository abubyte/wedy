import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/apps/client/pages/chats/chats_page.dart';
import 'package:wedy/core/theme/app_dimensions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';
import 'favorites/favorites_page.dart';

class ClientShellPage extends StatefulWidget {
  const ClientShellPage({super.key});

  @override
  State<ClientShellPage> createState() => _ClientShellPageState();
}

class _ClientShellPageState extends State<ClientShellPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ClientHomePage(),
    ClientChatsPage(),
    ClientFavoritesPage(),
    ClientProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
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
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingXS),
                child: Icon(IconsaxPlusLinear.home_1),
              ),
              label: 'Bosh sahifa',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingXS),
                child: Icon(IconsaxPlusLinear.message),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingXS),
                child: Icon(IconsaxPlusLinear.heart),
              ),
              label: 'Sevimli',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingXS),
                child: Icon(IconsaxPlusLinear.profile),
              ),
              label: 'Profil',
            ),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
