import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/apps/merchant/pages/tariff/tariff_payment_method_page.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/tariff/domain/entities/tariff.dart';
import 'package:wedy/features/tariff/presentation/bloc/tariff_bloc.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class TariffDurationPage extends StatefulWidget {
  final TariffPlan tariffPlan;

  const TariffDurationPage({super.key, required this.tariffPlan});

  @override
  State<TariffDurationPage> createState() => _TariffDurationPageState();
}

class _TariffDurationPageState extends State<TariffDurationPage> {
  int selectedDuration = 1; // months

  // Duration options with discounts
  static const List<_DurationOption> durationOptions = [
    _DurationOption(months: 1, discount: 0),
    _DurationOption(months: 3, discount: 10),
    _DurationOption(months: 6, discount: 20),
    _DurationOption(months: 12, discount: 30),
  ];

  _DurationOption get _selectedOption {
    return durationOptions.firstWhere((o) => o.months == selectedDuration, orElse: () => durationOptions.first);
  }

  double get _pricePerMonth => widget.tariffPlan.pricePerMonth;

  int get _totalPrice {
    final basePrice = _pricePerMonth * selectedDuration;
    final discount = _selectedOption.discount;
    return (basePrice * (100 - discount) / 100).round();
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    const WedyCircularButton(isPrimary: true),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Title
                    Text(
                      'Mudatni tanlang',
                      style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 24),
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Plan info header
                    _buildPlanHeader(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Subtitle
                    Text('Muddat tanlang:', style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Duration options
                    ...durationOptions.map((option) => _buildDurationCard(option)),
                  ],
                ),
              ),
            ),

            // Bottom button
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        color: AppColors.primaryLight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.tariffPlan.name,
            style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          Text(
            '${_formatPrice(_pricePerMonth.toInt())} so\'m/oy',
            style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(_DurationOption option) {
    final isSelected = selectedDuration == option.months;
    final basePrice = _pricePerMonth.toInt() * option.months;
    final discountedPrice = (basePrice * (100 - option.discount) / 100).round();
    final monthlyPrice = (discountedPrice / option.months).round();

    return GestureDetector(
      onTap: () => setState(() => selectedDuration = option.months),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration label
                Text(
                  option.months == 12 ? '1 yil' : '${option.months} oy',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                ),
                // Discount badge
                if (option.discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      'Chegirma: ${option.discount}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),

            // Price
            Text(
              '${_formatPrice(discountedPrice)} so\'m',
              style: AppTextStyles.headline2.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),

            // Monthly breakdown
            Text(
              option.months == 1
                  ? 'Bir oy uchun ko\'rish ochish qullay variant'
                  : '${option.months} oylik narx — ${_formatPrice(discountedPrice)} so\'m, bo oyiga ${_formatPrice(monthlyPrice)} degani',
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: WedyPrimaryButton(
          label: 'Davom etish',
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _navigateToPaymentMethod(context),
        ),
      ),
    );
  }

  void _navigateToPaymentMethod(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TariffBloc>(),
          child: TariffPaymentMethodPage(
            tariffPlan: widget.tariffPlan,
            durationMonths: selectedDuration,
            totalPrice: _totalPrice,
          ),
        ),
      ),
    );
  }
}

class _DurationOption {
  final int months;
  final int discount;

  const _DurationOption({required this.months, required this.discount});
}
