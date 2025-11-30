part of '../edit_page.dart';

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    this.dropdown = false,
    this.items,
    this.padding = false,
    this.hasLabel = true,
    this.suffix,
    this.button = false,
  });

  final String label;
  final bool dropdown;
  final bool padding;
  final bool hasLabel;
  final bool button;
  final Widget? suffix;
  final List<String>? items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ? const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLabel) ...[
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
          ],
          if (dropdown)
            DropdownButtonFormField(
              items: items?.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) {},
              style: AppTextStyles.bodyRegular,
              hint: Text(
                '${label}ni tanlang',
                style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
              icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: AppColors.textMuted),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
            )
          else
            TextField(
              readOnly: button,
              onTap: () {},
              decoration: InputDecoration(
                hintText: button ? 'Tanlang' : '${label}ni kiriting',
                hintStyle: button
                    ? AppTextStyles.bodyRegular
                    : AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                suffix: button
                    ? const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: AppColors.textMuted)
                    : suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
      ),
    );
  }
}
