part of '../service_page.dart';

class ServicePriceButton extends StatelessWidget {
  const ServicePriceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: const Color(0xFFD3E3FD),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Center(
        child: Text(
          "1 soati 300 000 so'm",
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF1E4ED8),
          ),
        ),
      ),
    );
  }
}
