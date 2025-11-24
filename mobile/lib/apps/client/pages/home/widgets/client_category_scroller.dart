part of '../home_page.dart';

class _ClientCategoryScroller extends StatelessWidget {
  const _ClientCategoryScroller({required this.categories});

  final List<_ClientCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.items, extra: category),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/ct${index + 1}.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        category.icon,
                        color: category.iconColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(category.label, style: AppTextStyles.categoryCaption),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.spacingM),
        itemCount: categories.length,
      ),
    );
  }
}
