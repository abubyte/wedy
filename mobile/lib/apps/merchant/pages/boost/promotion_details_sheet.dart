import 'package:flutter/material.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/featured_services/domain/entities/featured_service.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class PromotionDetailsSheet extends StatelessWidget {
  final FeaturedService featuredService;

  const PromotionDetailsSheet({super.key, required this.featuredService});

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  String _formatRemainingTime(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Tugagan';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return '$days kun $hours soat';
    } else {
      return '$hours soat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // Title
          Text(
            'Reklama ma\'lumotlari',
            style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // Details list
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Sotib olingan sana',
            value: _formatDate(featuredService.startDate),
            iconColor: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Tanlangan muddat',
            value: '${featuredService.daysDuration} kun',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          if (!featuredService.isFreeAllocation) ...[
            _buildDetailRow(
              icon: Icons.payments,
              label: 'To\'langan summa',
              value: '${_formatPrice(featuredService.amountPaid ?? 0)} uzs',
              iconColor: AppColors.success,
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          _buildDetailRow(
            icon: Icons.event,
            label: 'Tugash sanasi',
            value: _formatDate(featuredService.endDate),
            iconColor: AppColors.warning,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          _buildDetailRow(
            icon: Icons.timer,
            label: 'Qolgan vaqt',
            value: _formatRemainingTime(featuredService.endDate),
            iconColor: AppColors.info,
          ),
          const SizedBox(height: AppDimensions.spacingXL),

          // OK button
          SizedBox(
            width: double.infinity,
            child: WedyPrimaryButton(label: 'OK', onPressed: () => Navigator.of(context).pop()),
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted)),
        ),
        Text(value, style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  static Future<void> show(BuildContext context, FeaturedService featuredService) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PromotionDetailsSheet(featuredService: featuredService),
    );
  }
}
