part of '../service_page.dart';

class ServiceHeaderButtons extends StatelessWidget {
  const ServiceHeaderButtons({super.key, this.isMerchant = false});

  final bool isMerchant;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        isMerchant
            ? WedyCircularButton(
                icon: IconsaxPlusLinear.export_2,
                color: AppColors.primaryLight,
                borderColor: AppColors.primary,
                onTap: () {},
              )
            : const WedyCircularButton(),

        // Favorite & Share Buttons
        Row(
          children: [
            // Favorite Button
            isMerchant
                ? WedyCircularButton(icon: IconsaxPlusLinear.trend_up, isPrimary: true, onTap: () {})
                : const WedyCircularButton(icon: IconsaxPlusLinear.heart),
            const SizedBox(width: AppDimensions.spacingS),

            // Share Button
            isMerchant
                ? WedyCircularButton(
                    icon: IconsaxPlusLinear.edit,
                    isPrimary: true,
                    onTap: () => context.push(RouteNames.edit),
                  )
                : const WedyCircularButton(icon: IconsaxPlusLinear.export_2),
          ],
        ),
      ],
    );
  }
}
