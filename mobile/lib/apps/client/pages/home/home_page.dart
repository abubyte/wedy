import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wedy/apps/client/layouts/main_layout.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/core/di/injection_container.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_event.dart';
import 'package:wedy/features/category/presentation/bloc/category_state.dart';
import 'package:wedy/features/category/domain/entities/category.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/search_field.dart';
import 'widgets/featured_services_section.dart';
import 'widgets/category_services_section.dart';

part 'widgets/category_scroller.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    // Load categories (each category section will load its own services)
    context.read<CategoryBloc>().add(const LoadCategoriesEvent());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    // Refresh categories
    context.read<CategoryBloc>().add(const LoadCategoriesEvent());

    // Refresh all ServiceBlocs by finding them in the widget tree
    // Since each section has its own bloc, we'll complete refresh after a delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted && _refreshController.isRefresh) {
      _refreshController.refreshCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BlocProvider(create: (context) => getIt<ServiceBloc>()..add(const LoadServicesEvent(page: 1, limit: 50))),
        BlocProvider(create: (context) => getIt<CategoryBloc>()..add(const LoadCategoriesEvent())),
      ],
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, categoryState) {
          final categories = categoryState is CategoriesLoaded
              ? categoryState.categories.categories
              : <ServiceCategory>[];

          return ClientMainLayout(
            refreshController: _refreshController,
            onRefresh: _onRefresh,
            refreshHeader: const ClassicHeader(
              refreshingText: 'Yangilanmoqda...',
              completeText: 'Yangilandi!',
              idleText: 'Yangilash uchun torting',
              releaseText: 'Yangilash uchun qo\'yib yuboring',
              textStyle: TextStyle(color: AppColors.primary),
            ),
            expandedHeight: 195,
            collapsedHeight: 70,
            headerContent: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL, vertical: AppDimensions.spacingM),
                  child: ClientSearchField(
                    hintText: 'Qidirish',
                    readOnly: true,
                    onTap: () => context.pushNamed(RouteNames.search),
                  ),
                ),
                _CategoryScroller(categories: categories),
                const SizedBox(height: AppDimensions.spacingM),
              ],
            ),
            bodyChildren: [
              // Hot Offers Section (Featured Services) - has its own ServiceBloc
              const FeaturedServicesSection(),
              const SizedBox(height: AppDimensions.spacingL),

              // Services Section by Category - each category has its own ServiceBloc
              if (categories.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryServicesSection(category: category);
                  },
                  itemCount: categories.length,
                ),

              const SizedBox(height: AppDimensions.spacingM),
            ],
          );
        },
      ),
    );
  }
}

class ClientCategory {
  const ClientCategory({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}

const clientCategories = [
  ClientCategory(
    label: 'Decoratsiya',
    icon: IconsaxPlusLinear.colorfilter,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  ClientCategory(
    label: 'Sozandalar',
    icon: IconsaxPlusLinear.microphone,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  ClientCategory(
    label: 'Restoran',
    icon: IconsaxPlusLinear.cake,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  ClientCategory(
    label: 'Art',
    icon: IconsaxPlusLinear.magic_star,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  ClientCategory(
    label: 'Foto/Video',
    icon: IconsaxPlusLinear.camera,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
];
