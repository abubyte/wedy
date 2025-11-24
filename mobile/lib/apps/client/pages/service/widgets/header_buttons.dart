part of '../service_page.dart';

class ServiceHeaderButtons extends StatelessWidget {
  const ServiceHeaderButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: .5),
            ),
            child: const Center(child: Icon(IconsaxPlusLinear.arrow_left_1, color: Colors.black)),
          ),
        ),

        // Favorite & Share Buttons
        Row(
          children: [
            // Favorite Button
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: .5),
                ),
                child: const Center(child: Icon(IconsaxPlusLinear.heart, color: Colors.black)),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),

            // Share Button
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: .5),
                ),
                child: const Center(child: Icon(IconsaxPlusLinear.export_2, color: Colors.black)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
