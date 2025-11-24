part of '../service_page.dart';

class ServiceSocialTile extends StatelessWidget {
  const ServiceSocialTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse('https://t.me/wedybot'));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spacingS,
          horizontal: AppDimensions.spacingM,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: const Color(0xFFE0E0E0), width: .5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(IconsaxPlusLinear.mobile, size: 24, color: Colors.black),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              'Telegram',
              style: AppTextStyles.bodyRegular.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
