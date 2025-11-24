part of '../service_page.dart';

class ServiceReviews extends StatelessWidget {
  const ServiceReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        itemCount: 5,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.spacingS),
        itemBuilder: (context, index) {
          return Center(
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? AppDimensions.spacingL : 0,
                right: index == 4 ? AppDimensions.spacingL : 0,
              ),
              width: 300,
              padding: const EdgeInsets.all(AppDimensions.spacingSM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.border, width: .5),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          image: const DecorationImage(
                            image: NetworkImage('https://picsum.photos/200/300'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nurmuhammad',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              color: const Color(0xFF3B1752),
                            ),
                          ),
                          Text(
                            '9 Iyul 2025',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(IconsaxPlusBold.star_1, size: 9, color: Colors.yellow),
                              const SizedBox(width: AppDimensions.spacingXS),
                              Text(
                                '4.9',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'Biz to‘ylar uchun zamonaviy dekor xizmatlarini taqdim etamiz. Gul kompozitsiyalari, yorug‘lik va dizayn va bu h...',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
