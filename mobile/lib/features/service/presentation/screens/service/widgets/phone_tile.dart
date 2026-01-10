part of '../service_page.dart';

class ServicePhoneTile extends StatelessWidget {
  const ServicePhoneTile({super.key, required this.phoneNumber});

  final String phoneNumber;

  String _formatPhoneNumber(String phone) {
    // Format: +998 XX XXX XX XX
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    return '+998 ${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5, 7)} ${cleaned.substring(7, 9)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('tel:+998$phoneNumber')),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS, horizontal: AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(IconsaxPlusLinear.call_calling, size: 24, color: Colors.black),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              _formatPhoneNumber(phoneNumber),
              style: AppTextStyles.bodyRegular.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
