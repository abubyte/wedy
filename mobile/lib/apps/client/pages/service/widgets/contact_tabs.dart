part of '../service_page.dart';

class ServiceContactTabs extends StatelessWidget {
  const ServiceContactTabs({
    super.key,
    required this.isPhoneSelected,
    required this.isLocationSelected,
    required this.isSocialSelected,
    required this.onPhoneTap,
    required this.onLocationTap,
    required this.onSocialTap,
  });

  final bool isPhoneSelected;
  final bool isLocationSelected;
  final bool isSocialSelected;
  final VoidCallback onPhoneTap;
  final VoidCallback onLocationTap;
  final VoidCallback onSocialTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhoneTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: isPhoneSelected ? const Color(0xFFD3E3FD) : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Text(
                'Telefon',
                style: AppTextStyles.bodyRegular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          GestureDetector(
            onTap: onLocationTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: isLocationSelected
                    ? const Color(0xFFD3E3FD)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Text(
                'Manzil',
                style: AppTextStyles.bodyRegular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          GestureDetector(
            onTap: onSocialTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: isSocialSelected
                    ? const Color(0xFFD3E3FD)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Text(
                'Ijtimoiy tarmoqlar',
                style: AppTextStyles.bodyRegular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
