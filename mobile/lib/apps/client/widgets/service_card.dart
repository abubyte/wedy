import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/shared/navigation/route_names.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class ClientServiceCard extends StatelessWidget {
  const ClientServiceCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.category,
    this.rating,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onTap,
    this.width,
    this.height,
  });

  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String category;
  final double? rating;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => context.push(RouteNames.serviceDetails),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        width: width ?? (MediaQuery.of(context).size.width - AppDimensions.spacingL * 2) / 2,
        height: height ?? double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            height != null
                ? SizedBox(height: (height ?? 0) - 100, child: _buildImage())
                : Expanded(child: _buildImage()),
            const SizedBox(height: AppDimensions.spacingXS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: " so'm",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$location • $category',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppDimensions.radiusM)),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceMuted,
                alignment: Alignment.center,
                child: const Icon(IconsaxPlusLinear.image, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        if (rating != null && rating! > 0)
          Positioned(
            top: AppDimensions.spacingS,
            left: AppDimensions.spacingS,
            child: Container(
              width: 45,
              height: 23,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusBold.star, color: Color(0xFFFFC120), size: 9),
                    const SizedBox(width: 4),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: AppDimensions.spacingS,
          right: AppDimensions.spacingS,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              height: 23,
              width: 23,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Center(
                child: Icon(
                  isFavorite ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                  size: 15,
                  color: isFavorite ? AppColors.primary : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
