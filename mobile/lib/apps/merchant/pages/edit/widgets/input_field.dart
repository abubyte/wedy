part of '../edit_page.dart';

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    this.dropdown = false,
    this.regions,
    this.categories,
    this.padding = false,
    this.hasLabel = true,
    this.suffix,
    this.button = false,
    this.controller,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.selectedCategory,
    this.selectedRegion,
    this.onCategoryChanged,
    this.onRegionChanged,
    this.onLocationTap,
  });

  final String label;
  final bool dropdown;
  final bool padding;
  final bool hasLabel;
  final bool button;
  final Widget? suffix;
  final List<ServiceCategory>? categories;
  final List<String>? regions;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final ServiceCategory? selectedCategory;
  final String? selectedRegion;
  final ValueChanged<ServiceCategory>? onCategoryChanged;
  final ValueChanged<String>? onRegionChanged;
  final VoidCallback? onLocationTap;

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
          if (dropdown && categories != null)
            DropdownButtonFormField<ServiceCategory>(
              initialValue: selectedCategory,
              items: categories!.map((category) {
                return DropdownMenuItem<ServiceCategory>(value: category, child: Text(category.name));
              }).toList(),
              onChanged: (category) {
                if (category != null && onCategoryChanged != null) {
                  onCategoryChanged!(category);
                }
              },
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
              validator: (value) {
                if (value == null) {
                  return validator?.call(null);
                }
                return null;
              },
            )
          else if (dropdown && regions != null)
            DropdownButtonFormField<String>(
              initialValue: selectedRegion,
              items: regions!.map((region) {
                return DropdownMenuItem<String>(value: region, child: Text(region));
              }).toList(),
              onChanged: (region) {
                if (region != null && onRegionChanged != null) {
                  onRegionChanged!(region);
                }
              },
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
              validator: validator,
            )
          else if (button)
            TextFormField(
              readOnly: true,
              onTap: onLocationTap,
              validator: validator,
              decoration: InputDecoration(
                hintText: 'Tanlang',
                hintStyle: AppTextStyles.bodyRegular,
                suffix: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: AppColors.textMuted),
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
            TextFormField(
              controller: controller,
              validator: validator,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: AppTextStyles.bodyRegular,
              decoration: InputDecoration(
                hintText: '${label}ni kiriting',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                suffix: suffix,
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
