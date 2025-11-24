part of '../service_page.dart';

class CallButton extends StatelessWidget {
  const CallButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL, vertical: AppDimensions.spacingS),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0xFF5B758F), blurRadius: 15.7)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E3FD),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Center(
                child: Text(
                  'Chat',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),

          Expanded(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:+998991234567')),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A8EF4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: const Color(0xFF1E4ED8), width: .5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(IconsaxPlusLinear.call_calling, size: 24, color: Colors.white),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      'Qo\'ng\'iroq',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
