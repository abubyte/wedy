import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cards/service_card.dart';

class MerchantFavoritesPage extends StatelessWidget {
  const MerchantFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const services = _mockFavoriteServices;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sevimlilar',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Expanded(
                child: GridView.builder(
                  itemCount: services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppDimensions.spacingM,
                    mainAxisSpacing: AppDimensions.spacingM,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return ServiceCard(
                      imageUrl: service.imageUrl,
                      title: service.title,
                      price: service.price,
                      location: service.location,
                      category: service.category,
                      rating: service.rating,
                      isFavorite: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteService {
  const _FavoriteService({
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

const _mockFavoriteServices = [
  _FavoriteService(
    imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=60',
    title: 'Luxury Decor Sam',
    price: '9 999 999 so\'m',
    location: 'Toshkent',
    category: 'Dekor',
    rating: 5.0,
  ),
  _FavoriteService(
    imageUrl: 'https://images.unsplash.com/photo-1543353071-10c8ba85a904?auto=format&fit=crop&w=800&q=60',
    title: 'Golden Catering',
    price: '7 200 000 so\'m',
    location: 'Farg\'ona',
    category: 'Oziq-ovqat',
    rating: 4.8,
  ),
  _FavoriteService(
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=60',
    title: 'Event Light Studio',
    price: '4 500 000 so\'m',
    location: 'Samarqand',
    category: 'Yorug\'lik',
    rating: 4.9,
  ),
  _FavoriteService(
    imageUrl: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=800&q=60',
    title: 'Dream Wedding Band',
    price: '12 800 000 so\'m',
    location: 'Toshkent',
    category: 'Sozandalar',
    rating: 4.7,
  ),
];
