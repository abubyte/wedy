part of '../service_page.dart';

class ServicePriceButton extends StatelessWidget {
  final double price;
  final String priceType;

  const ServicePriceButton({super.key, required this.price, required this.priceType});

  String _formatPrice(double price) {
    // Format price with thousand separators
    final priceStr = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(priceStr[i]);
    }

    if (priceType == 'fixed') return '${buffer.toString()} so\'m';
    if (priceType == 'daily') return "1 kun ${buffer.toString()} so'm";
    if (priceType == 'hourly') return "1 soati ${buffer.toString()} so'm";
    if (priceType == 'person') return "1 kishi uchun ${buffer.toString()} so'm";

    return 'Kelishamiz';
  }

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
          _formatPrice(price),
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
