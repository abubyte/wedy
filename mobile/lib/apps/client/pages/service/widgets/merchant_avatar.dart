part of '../service_page.dart';

class ServiceMerchantAvatar extends StatelessWidget {
  const ServiceMerchantAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.195,
      child: Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: const [
            BoxShadow(color: Color(0xFF5A8EF4), blurRadius: 30),
          ],
          image: const DecorationImage(
            image: NetworkImage('https://picsum.photos/200/300'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
