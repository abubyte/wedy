import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/constants/app_dimensions.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key, required this.child, this.client = true});

  final StatefulNavigationShell child;
  final bool client;

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  final clientItems = <_BottomNavItem>[
    _BottomNavItem(label: 'Bosh sahifa', icon: IconsaxPlusLinear.home_1),
    _BottomNavItem(label: 'Chat', icon: IconsaxPlusLinear.message),
    _BottomNavItem(label: 'Sevimli', icon: IconsaxPlusLinear.heart),
    _BottomNavItem(label: 'Profil', icon: IconsaxPlusLinear.profile),
  ];

  final merchantItems = <_BottomNavItem>[
    _BottomNavItem(label: 'Bosh sahifa', icon: IconsaxPlusLinear.home_trend_up),
    _BottomNavItem(label: 'Sahifam', icon: IconsaxPlusLinear.personalcard),
    _BottomNavItem(label: 'Chatlar', icon: IconsaxPlusLinear.message),
    _BottomNavItem(label: 'Sozlamalar', icon: IconsaxPlusLinear.setting_2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.child.currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          items: (widget.client ? clientItems : merchantItems)
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
                    child: Icon(item.icon),
                  ),
                  label: item.label,
                ),
              )
              .toList(),
          onTap: (index) => widget.child.goBranch(index, initialLocation: index == widget.child.currentIndex),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData icon;

  _BottomNavItem({required this.label, required this.icon});
}
