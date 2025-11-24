import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/apps/client/layouts/main_layout.dart';
import 'package:wedy/apps/client/pages/home/home_page.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/apps/client/widgets/service_card.dart';
import 'package:wedy/apps/client/widgets/search_field.dart';

part 'widgets/category_meta_card.dart';
part 'widgets/hot_offers_meta_card.dart';

class ClientItemsPage extends StatelessWidget {
  const ClientItemsPage({super.key, this.hotOffers = false});

  final bool hotOffers;

  @override
  Widget build(BuildContext context) {
    final items = hotOffers ? _hotOffersItems : _allItems;
    final category = clientCategories[0];

    return ClientMainLayout(
      expandedHeight: 80,
      collapsedHeight: 70,
      headerContent: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: const Row(
          children: [
            WedyCircularButton(),
            SizedBox(width: AppDimensions.spacingS),
            Expanded(child: ClientSearchField()),
            SizedBox(width: AppDimensions.spacingS),
            WedyCircularButton(icon: IconsaxPlusLinear.filter),
          ],
        ),
      ),

      bodyChildren: [
        // Page Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: !hotOffers ? _HotOffersMetaCard(category: category) : const _CategoryMetaCard(),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Items list
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.spacingL,
            right: AppDimensions.spacingL,
            bottom: AppDimensions.spacingL,
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    ((MediaQuery.of(context).size.width - AppDimensions.spacingL * 2) / 2) -
                    AppDimensions.spacingL -
                    AppDimensions.spacingS,
                child: ClientServiceCard(
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
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1519680772-8b58b81a0132?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '9 999 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '8 500 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?auto=format&fit=crop&w=800&q=60',
    title: 'Bu yerda nom bo\'ladi...',
    price: '6 200 000',
    location: 'Andijon',
    category: 'Foto/Video',
    rating: 4.6,
  ),
];

const _allItems = [
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?auto=format&fit=crop&w=800&q=60',
    title: 'Decoratsiya studiyasi',
    price: '4 800 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    title: 'Gourmet Catering',
    price: '7 500 000',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1526045478516-99145907023c?auto=format&fit=crop&w=800&q=60',
    title: 'Joyful Artists',
    price: '3 200 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1472653431158-6364773b2a56?auto=format&fit=crop&w=800&q=60',
    title: 'Premium Wedding Band',
    price: '10 000 000',
    location: 'Buxoro',
    category: 'Sozandalar',
    rating: 4.8,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?auto=format&fit=crop&w=800&q=60',
    title: 'Professional Photography',
    price: '6 200 000',
    location: 'Andijon',
    category: 'Foto/Video',
    rating: 4.6,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=60',
    title: 'Elegant Event Planning',
    price: '9 999 999',
    location: 'Toshkent',
    category: 'Oziq-ovqat',
    rating: 5.0,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1519680772-8b58b81a0132?auto=format&fit=crop&w=800&q=60',
    title: 'Luxury Venue Services',
    price: '12 500 000',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 4.9,
  ),
  _Item(
    imageUrl: 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=60',
    title: 'Creative Design Studio',
    price: '5 800 000',
    location: 'Samarqand',
    category: 'Art',
    rating: 4.7,
  ),
];
