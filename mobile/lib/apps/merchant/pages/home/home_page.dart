import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cards/service_card.dart';
import '../../../../shared/widgets/inputs/search_field.dart';

class MerchantHomePage extends StatelessWidget {
  const MerchantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = _mockCategories;
    const services = _mockServices;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spacingL,
                  right: AppDimensions.spacingL,
                  top: AppDimensions.spacingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assalomu alaykum!',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text('Qaynoq takliflar!', style: AppTextStyles.headline2),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: WedySearchField(
                hintText: 'Qidirish',
                margin: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                  vertical: AppDimensions.spacingM,
                ),
                trailing: Padding(
                  padding: EdgeInsets.only(right: AppDimensions.spacingS),
                  child: Icon(
                    IconsaxPlusLinear.setting_4,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: _CategoryScroller(categories: categories),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                  vertical: AppDimensions.spacingL,
                ),
                child: _FeaturedBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL,
              ),
              sliver: SliverToBoxAdapter(
                child: Text('Decoratsiya', style: AppTextStyles.title2),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final service = services[index];
                  return ServiceCard(
                    imageUrl: service.imageUrl,
                    title: service.title,
                    price: service.price,
                    location: service.location,
                    category: service.category,
                    rating: service.rating,
                    isFavorite: index % 2 == 0,
                  );
                }, childCount: services.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.spacingM,
                  mainAxisSpacing: AppDimensions.spacingM,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({required this.categories});

  final List<_Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  child: Icon(
                    category.icon,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(category.label, style: AppTextStyles.caption),
            ],
          );
        },
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.spacingM),
        itemCount: categories.length,
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6AA9FF), Color(0xFF5A8EF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eng yaxshi xizmat va mahsulotlar shu yerda.',
                  style: AppTextStyles.title2.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'Bugun yangi mijozlar bilan tanishing.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.textInverse,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingM),
              child: Icon(
                IconsaxPlusLinear.arrow_right,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Category {
  const _Category({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _Service {
  const _Service({
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

const _mockCategories = [
  _Category(label: 'Decoratsiya', icon: IconsaxPlusLinear.colorfilter),
  _Category(label: 'Sozandalar', icon: IconsaxPlusLinear.microphone),
  _Category(label: 'Restoran', icon: IconsaxPlusLinear.cake),
  _Category(label: 'Art', icon: IconsaxPlusLinear.magic_star),
  _Category(label: 'Foto/Video', icon: IconsaxPlusLinear.camera),
];

const _mockServices = [
  _Service(
    imageUrl:
        'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=800&q=60',
    title: 'Sam dekor - professional bezak xizmatlari',
    price: '9 999 999 999 so\'m',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Service(
    imageUrl:
        'https://images.unsplash.com/photo-1519680772-8b58b81a0132?auto=format&fit=crop&w=800&q=60',
    title: 'Royal Catering',
    price: '6 500 000 so\'m',
    location: 'Samarqand',
    category: 'Ketring',
    rating: 4.8,
  ),
  _Service(
    imageUrl:
        'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=60',
    title: 'Happy Moments decor',
    price: '3 200 000 so\'m',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Service(
    imageUrl:
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=60',
    title: 'Wedding Masters',
    price: '12 000 000 so\'m',
    location: 'Buxoro',
    category: 'To\'y xizmatlari',
    rating: 5.0,
  ),
];
