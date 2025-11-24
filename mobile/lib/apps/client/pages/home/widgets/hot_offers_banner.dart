part of '../home_page.dart';

class _HotOffersBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(RouteNames.hotOffers);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFFD3E3FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
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
                      style: AppTextStyles.title1.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusPill,
                      ),
                      border: Border.all(
                        color: AppColors.primaryDark,
                        width: .5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        IconsaxPlusLinear.arrow_right_3,
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
            const SizedBox(height: AppDimensions.spacingS),

            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: SizedBox(
                height: 211,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _hotOffers.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: AppDimensions.spacingS);
                  },
                  itemBuilder: (context, index) {
                    final offer = _hotOffers[index];
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? AppDimensions.spacingS : 0,
                          right: index == _hotOffers.length - 1
                              ? AppDimensions.spacingS
                              : 0,
                        ),
                        child: AspectRatio(
                          aspectRatio: .7,
                          child: ServiceCard(
                            imageUrl: offer.imageUrl,
                            title: offer.title,
                            price: offer.price,
                            location: offer.location,
                            category: offer.category,
                            rating: offer.rating,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
