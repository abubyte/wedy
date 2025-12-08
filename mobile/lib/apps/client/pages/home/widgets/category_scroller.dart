part of '../home_page.dart';

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({required this.categories});

  final List<ServiceCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => context.pushNamed(RouteNames.items, extra: category),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Center(
                    child: category.iconUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            child: Image.network(
                              category.iconUrl!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(IconsaxPlusLinear.category, color: AppColors.primary, size: 28),
                            ),
                          )
                        : const Icon(IconsaxPlusLinear.category, color: AppColors.primary, size: 28),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                SizedBox(
                  width: 72,
                  child: Text(
                    category.name,
                    style: AppTextStyles.categoryCaption,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.spacingM),
        itemCount: categories.length,
      ),
    );
  }
}
