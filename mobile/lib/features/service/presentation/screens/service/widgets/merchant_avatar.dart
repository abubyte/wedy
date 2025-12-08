part of '../service_page.dart';

class ServiceMerchantAvatar extends StatelessWidget {
  final MerchantBasicInfo merchant;

  const ServiceMerchantAvatar({super.key, required this.merchant});

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
          boxShadow: const [BoxShadow(color: Color(0xFF5A8EF4), blurRadius: 30)],
          image: merchant.avatarUrl != null
              ? DecorationImage(image: NetworkImage(merchant.avatarUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: merchant.avatarUrl == null ? const Icon(IconsaxPlusLinear.profile, size: 70, color: Colors.black) : null,
      ),
    );
  }
}
