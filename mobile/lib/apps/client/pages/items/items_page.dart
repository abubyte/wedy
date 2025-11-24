import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/apps/client/pages/home/home_page.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/cards/service_card.dart';
import 'package:wedy/shared/widgets/inputs/search_field.dart';

class ClientItemsPage extends StatelessWidget {
  const ClientItemsPage({super.key, this.hotOffers = false});

  final bool hotOffers;

  @override
  Widget build(BuildContext context) {
    final items = hotOffers ? _hotOffersItems : _allItems;
    final category = clientCategories[0];

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, innerBoxIsScrollable) {
            return [
              SliverAppBar(
                floating: true,
                expandedHeight: 80,
                collapsedHeight: 70,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.background,
                flexibleSpace: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingL),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusPill,
                                ),
                                color: AppColors.surface,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: .5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  IconsaxPlusLinear.arrow_left_1,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          const Expanded(
                            child: SizedBox(
                              height: 43,
                              child: WedySearchField(),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusPill,
                                ),
                                color: AppColors.surface,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: .5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  IconsaxPlusLinear.filter,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
          body: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE0E0E0), width: .5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppDimensions.spacingL,
                        right: AppDimensions.spacingL,
                        top: AppDimensions.spacingL,
                        bottom: AppDimensions.spacingM,
                      ),
                      child: !hotOffers
                          ? Container(
                              width: double.infinity,
                              height: 82,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusL,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: .5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingL,
                                vertical: AppDimensions.spacingS,
                              ),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    'assets/images/ct1.png',
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppColors.surfaceMuted,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        IconsaxPlusLinear.image,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 65, height: 82),

                                      Expanded(
                                        child: Text(
                                          category.label,
                                          style: AppTextStyles.bodyRegular
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              height: 75,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusL,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: .5,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFFD3E3FD),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusL,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                    width: .5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacingS,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Qaynoq takliflar!',
                                              style: AppTextStyles.title1
                                                  .copyWith(
                                                    color:
                                                        AppColors.textInverse,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDimensions.spacingM,
                                          ),
                                          Container(
                                            height: 24,
                                            width: 24,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppDimensions.radiusPill,
                                                  ),
                                              border: Border.all(
                                                color: AppColors.primaryDark,
                                                width: .5,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                IconsaxPlusLinear.lamp_on,
                                                color: AppColors.textInverse,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacingS,
                                      ),
                                      child: Text(
                                        'Eng yaxshi xizmat va mahsulotlar shu yerda.',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textInverse,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppDimensions.spacingS,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Items list
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item {
  const _Item({
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

const _hotOffersItems = [
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1519680772-8b58b81a0132?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '8 500 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '6 200 000',
    location: 'Andijon',
    category: 'Foto/Video',
    rating: 4.6,
  ),
];

const _allItems = [
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Decoratsiya studiyasi',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Gourmet Catering',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Joyful Artists',
    price: '3 200 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Premium Wedding Band',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?auto=format&fit=crop&w=800&q=60',
    title: 'Professional Photography',
    price: '6 200 000',
    location: 'Andijon',
    category: 'Foto/Video',
    rating: 4.6,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=60',
    title: 'Elegant Event Planning',
    price: '9 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1519680772-8b58b81a0132?auto=format&fit=crop&w=800&q=60',
    title: 'Luxury Venue Services',
    price: '12 500 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Item(
    imageUrl:
        'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=60',
    title: 'Creative Design Studio',
    price: '5 800 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
];
