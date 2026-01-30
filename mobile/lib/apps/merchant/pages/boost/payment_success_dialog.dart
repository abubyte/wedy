import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class PaymentSuccessDialog extends StatelessWidget {
  final int durationDays;

  const PaymentSuccessDialog({super.key, required this.durationDays});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withValues(alpha: 0.2)),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 80),
              ),
              const SizedBox(height: AppDimensions.spacingXL),

              // Success title
              Text(
                'Muvaffaqiyatli!',
                style: AppTextStyles.headline1.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // Success message
              Text(
                'To\'lov qabul qilindi. Reklama siz tanlagan va $durationDays kun davomida xizmatlarda aktiv bo\'ladi.',
                style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXL * 2),

              // OK button
              SizedBox(
                width: double.infinity,
                child: WedyPrimaryButton(
                  label: 'OK',
                  onPressed: () {
                    // Pop all boost-related pages and go back to home
                    context.go('/home');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, {required int durationDays}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuccessDialog(durationDays: durationDays),
    );
  }
}
