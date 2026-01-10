part of '../service_page.dart';

class ServicePhoneTile extends StatelessWidget {
  const ServicePhoneTile({super.key, required this.phoneNumber});

  final String phoneNumber;

  String _formatPhoneNumber(String phone) {
    // Format: +998 XX XXX XX XX
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length == 12 && cleaned.startsWith('998')) {
      return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8, 10)} ${cleaned.substring(10)}';
    } else if (cleaned.length == 13 && cleaned.startsWith('+998')) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9, 11)} ${cleaned.substring(11)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final tel = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';
        launchUrl(Uri.parse('tel:$tel'));
      },
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
