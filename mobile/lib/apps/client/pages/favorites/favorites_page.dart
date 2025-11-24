import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cards/service_card.dart';

class ClientFavoritesPage extends StatelessWidget {
  const ClientFavoritesPage({super.key});

  final items = _results;
  final empty = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!empty) ...[
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Text('Sevimlilar', style: AppTextStyles.headline2),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.spacingL,
                    right: AppDimensions.spacingL,
                    bottom: AppDimensions.spacingL,
                  ),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppDimensions.spacingS,
                          mainAxisSpacing: AppDimensions.spacingS,
                          childAspectRatio: .8,
                        ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width:
                            ((MediaQuery.of(context).size.width -
                                    AppDimensions.spacingL * 2) /
                                2) -
                            AppDimensions.spacingL -
                            AppDimensions.spacingS,
                        child: ServiceCard(
                          imageUrl: items[index].imageUrl,
                          title: items[index].title,
                          price: items[index].price,
                          location: items[index].location,
                          category: items[index].category,
                          rating: items[index].rating,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (empty) ...[
                SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 63,
                          height: 63,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                          ),
                          child: const Icon(
                            IconsaxPlusLinear.heart_search,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        Text(
                          'Sevimli elonlaringiz yo\'q',
                          style: AppTextStyles.headline2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchService {
  const _SearchService({
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

const _results = [
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Decoratsiya studiyasi',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Gourmet Catering',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Joyful Artists',
    price: '3 200 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Premium Wedding Band',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Decoratsiya studiyasi',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Gourmet Catering',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Joyful Artists',
    price: '3 200 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Premium Wedding Band',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Decoratsiya studiyasi',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Gourmet Catering',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Joyful Artists',
    price: '3 200 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _SearchService(
    imageUrl:
        'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Premium Wedding Band',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
];
