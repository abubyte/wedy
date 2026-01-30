import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/tariff/domain/entities/tariff.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_bloc.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_event.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_state.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class TariffPaymentMethodPage extends StatelessWidget {
  final TariffPlan tariffPlan;
  final int durationMonths;
  final int totalPrice;

  const TariffPaymentMethodPage({
    super.key,
    required this.tariffPlan,
    required this.durationMonths,
    required this.totalPrice,
  });

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TariffBloc, TariffState>(
      listener: (context, state) async {
        if (state is PaymentCreated) {
          final paymentUrl = state.payment.paymentUrl;
          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            // Show processing dialog
            _showProcessingDialog(context);

            final uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                Navigator.of(context).pop(); // Close processing dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('To\'lov sahifasini ochib bo\'lmadi'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          }
        } else if (state is TariffError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is TariffLoading;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  const WedyCircularButton(isPrimary: true),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Title
                  Text(
                    'To\'lov usulini tanlang',
                    style: AppTextStyles.headline2
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 24),
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),

                  // Amount display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reklama:',
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_formatPrice(totalPrice)} so\'m',
                        style: AppTextStyles.headline2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'To\'lov usullaringizni tanlang',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),

                  // Payment Methods
                  _buildPaymentMethodCard(
                    context: context,
                    title: 'Payme',
                    isLoading: isLoading,
                    onTap: () => _initiatePayment(context, 'payme'),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildPaymentMethodCard(
                    context: context,
                    title: 'Click',
                    isLoading: isLoading,
                    onTap: () => _initiatePayment(context, 'click'),
                    enabled: false, // Click not implemented yet
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required String title,
    required bool isLoading,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border, width: 1),
            color: AppColors.surface,
          ),
          child: Row(
            children: [
              // Logo placeholder - using text for now
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Center(
                  child: Text(
                    title.toLowerCase() == 'payme' ? 'pay me' : 'Click',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: title.toLowerCase() == 'payme'
                          ? const Color(0xFF00CDAC)
                          : const Color(0xFF0066FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!enabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    'Tez orada',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              if (enabled)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _initiatePayment(BuildContext context, String paymentMethod) {
    context.read<TariffBloc>().add(
          CreateTariffPaymentEvent(
            tariffPlanId: tariffPlan.id,
            durationMonths: durationMonths,
            paymentMethod: paymentMethod,
          ),
        );
  }

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _TariffPaymentProcessingDialog(),
    );
  }
}

class _TariffPaymentProcessingDialog extends StatelessWidget {
  const _TariffPaymentProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'To\'lovingiz tasdiqlanmoqda...',
              style: AppTextStyles.headline2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'Iltimos, jarayon tugaguncha dasturni o\'chirmang.\nBiz sizning to\'lovingizni tekshirish uchun\nprovayderdan javob poymiz beramiz.',
              style: AppTextStyles.bodyRegular.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TariffPaymentSuccessDialog extends StatelessWidget {
  final int durationMonths;

  const TariffPaymentSuccessDialog({
    super.key,
    required this.durationMonths,
  });

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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 80,
                ),
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
                'To\'lov qabul qilindi. Tarif faollashtirildi va $durationMonths oy davomida faol bo\'ladi.',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXL * 2),

              // OK button
              SizedBox(
                width: double.infinity,
                child: WedyPrimaryButton(
                  label: 'OK',
                  onPressed: () {
                    // Pop all tariff-related pages and go back to home
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

  static Future<void> show(BuildContext context, {required int durationMonths}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TariffPaymentSuccessDialog(durationMonths: durationMonths),
    );
  }
}
