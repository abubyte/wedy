import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/apps/client/layouts/main_layout.dart';
import 'package:wedy/apps/client/widgets/section_header.dart';
import 'package:wedy/shared/navigation/route_names.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/service_card.dart';
import '../../widgets/search_field.dart';

part 'widgets/hot_offers_banner.dart';
part 'widgets/category_scroller.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = clientCategories;
    const hotOffers = _hotOffers;

    return ClientMainLayout(
      expandedHeight: 195,
      collapsedHeight: 70,
      headerContent: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL, vertical: AppDimensions.spacingM),
            child: ClientSearchField(hintText: 'Qidirish'),
          ),
          _CategoryScroller(categories: categories),
          SizedBox(height: AppDimensions.spacingM),
        ],
      ),
      bodyChildren: [
        // Hot Offers Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: _HotOffersBanner(),
        ),
        const SizedBox(height: AppDimensions.spacingL),

        // Services Section
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final category = clientCategories[index];
            return Column(
              children: [
                // Section Header
                ClientSectionHeader(
                  title: category.label,
                  onTap: () => context.pushNamed(RouteNames.items, extra: category),
                  applyPadding: true,
                ),
                const SizedBox(height: AppDimensions.spacingS),

                // Services
                SizedBox(
                  height: 211,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = hotOffers[index];
                      return SizedBox(
                        width: 150,
                        child: ClientServiceCard(
                          imageUrl: item.imageUrl,
                          title: item.title,
                          price: item.price,
                          location: item.location,
                          category: item.category,
                          rating: item.rating,
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.spacingS),
                    itemCount: hotOffers.length,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
              ],
            );
          },
          itemCount: clientCategories.length,
        ),

        const SizedBox(height: AppDimensions.spacingM),
      ],
    );
  }
}

class _ClientCategory {
  const _ClientCategory({
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

class _ClientService {
  const _ClientService({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.category,
    this.rating,
  });

  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String category;
  final double? rating;
}

const clientCategories = [
  _ClientCategory(
    label: 'Decoratsiya',
    icon: IconsaxPlusLinear.colorfilter,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  _ClientCategory(
    label: 'Sozandalar',
    icon: IconsaxPlusLinear.microphone,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  _ClientCategory(
    label: 'Restoran',
    icon: IconsaxPlusLinear.cake,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  _ClientCategory(
    label: 'Art',
    icon: IconsaxPlusLinear.magic_star,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
  _ClientCategory(
    label: 'Foto/Video',
    icon: IconsaxPlusLinear.camera,
    backgroundColor: Color(0xFFD3E3FD),
    iconColor: Colors.black,
  ),
];

const _hotOffers = [
  _ClientService(
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _ClientService(
    imageUrl:
        'https://images.unsplash.com/photo-1763162944506-ee1fbaf5a733?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxmZWF0dXJlZC1waG90b3MtZmVlZHw0fHx8ZW58MHx8fHx8',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _ClientService(
    imageUrl: 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
];
