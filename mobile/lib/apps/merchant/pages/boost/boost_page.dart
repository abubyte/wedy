import 'package:flutter/material.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

class BoostPage extends StatefulWidget {
  const BoostPage({super.key});

  @override
  State<BoostPage> createState() => _BoostPageState();
}

class _BoostPageState extends State<BoostPage> {
  int days = 122;
  static const int minDays = 1;
  static const int maxDays = 365;
  static const int basePricePerDay = 20000; // UZS

  double get _sliderValue => (days - minDays) / (maxDays - minDays);

  int _calculatePrice() {
    if (days >= 1 && days <= 7) {
      return basePricePerDay; // 0% discount
    } else if (days >= 8 && days <= 30) {
      return (basePricePerDay * 0.9).toInt(); // 10% discount
    } else if (days >= 31 && days <= 90) {
      return (basePricePerDay * 0.8).toInt(); // 20% discount
    } else {
      return (basePricePerDay * 0.7).toInt(); // 30% discount
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricePerDay = _calculatePrice();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
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
                'Necha kunga reklama qilmoqchisiz?, Tanlang:',
                style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 24),
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Period selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.border, width: .5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Kunlar soni',
                          style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            color: AppColors.primaryLight,
                          ),
                          child: Text(
                            days.toString(),
                            style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Custom Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primaryLight,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.1),

                        trackHeight: 5,
                      ),
                      child: Slider(
                        value: _sliderValue,
                        onChanged: (value) {
                          setState(() {
                            days = (value * (maxDays - minDays) + minDays).round();
                          });
                        },
                        min: 0,
                        max: 1,
                      ),
                    ),

                    // Min/Max labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$minDays kun',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                        ),
                        Text(
                          '$maxDays kun',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacingM),

                    // Price per day
                    Text(
                      '${pricePerDay.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS/kun',
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
