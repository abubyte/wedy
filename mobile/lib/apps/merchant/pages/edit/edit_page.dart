import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wedy/apps/client/pages/home/home_page.dart';
import 'package:wedy/core/constants/uzbekistan_data.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:widgets_easier/widgets_easier.dart';

part 'widgets/input_field.dart';

class MerchantEditPage extends StatefulWidget {
  const MerchantEditPage({super.key});

  @override
  State<MerchantEditPage> createState() => _MerchantEditPageState();
}

class _MerchantEditPageState extends State<MerchantEditPage> {
  XFile? pickedFile;

  bool isFixedSelected = true;
  bool isCustomSelected = false;
  bool isDailySelected = false;
  bool isHourlySelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Elon yaratish',
                      style: AppTextStyles.headline2.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXXL),

                Transform.rotate(
                  angle: 0.195,
                  child: GestureDetector(
                    onTap: () async {
                      // Use ImagePicker to pick image from gallery
                      final picker = ImagePicker();
                      pickedFile = await picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        setState(() {});
                      }
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: ShapeDecoration(
                        color: AppColors.surface,
                        shape: DashedBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                          width: 1,
                          color: AppColors.primary,
                          dashSize: 3,
                          dashSpacing: pickedFile?.path == null ? 2 : 0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        child: pickedFile?.path == null
                            ? const Center(
                                child: Image(image: AssetImage('assets/icons/image_icon.png'), width: 77, height: 77),
                              )
                            : Image(image: FileImage(File(pickedFile!.path)), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingL),

                const _InputField(label: 'Nom', padding: true),
                const _InputField(label: 'Foydalanuvchi nomi', padding: true),
                _InputField(
                  label: 'Kategoriya',
                  dropdown: true,
                  items: clientCategories.map((category) => category.label).toList(),
                  padding: true,
                ),
                _InputField(
                  label: 'Viloyat',
                  dropdown: true,
                  items: UzbekistanData.regionNames.values.toList(),
                  padding: true,
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Xizmat narxi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                SizedBox(
                  height: 35,
                  child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFixedSelected = true;
                            isCustomSelected = false;
                            isDailySelected = false;
                            isHourlySelected = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          margin: const EdgeInsets.only(left: AppDimensions.spacingL),
                          decoration: BoxDecoration(
                            color: isFixedSelected ? const Color(0xFFD3E3FD) : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                          ),
                          child: Text(
                            'Aniq narx',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFixedSelected = false;
                            isCustomSelected = true;
                            isDailySelected = false;
                            isHourlySelected = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: isCustomSelected ? const Color(0xFFD3E3FD) : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                          ),
                          child: Text(
                            'Kelishamiz',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFixedSelected = false;
                            isCustomSelected = false;
                            isDailySelected = true;
                            isHourlySelected = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: isDailySelected ? const Color(0xFFD3E3FD) : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                          ),
                          child: Text(
                            'Kunlik',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFixedSelected = false;
                            isCustomSelected = false;
                            isDailySelected = false;
                            isHourlySelected = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          margin: const EdgeInsets.only(right: AppDimensions.spacingL),
                          decoration: BoxDecoration(
                            color: isHourlySelected ? const Color(0xFFD3E3FD) : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                          ),
                          child: Text(
                            'Soatlik',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                if (!isCustomSelected)
                  _InputField(
                    label: 'Narx',
                    hasLabel: false,
                    padding: true,
                    suffix: Text('/so\'m', style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted)),
                  ),

                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return const SizedBox(width: AppDimensions.spacingM);
                    },
                    itemCount: 5,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 300,
                        height: 300,
                        margin: EdgeInsets.only(
                          left: index == 0 ? AppDimensions.spacingL : 0,
                          right: index == 4 ? AppDimensions.spacingL : 0,
                        ),
                        decoration: ShapeDecoration(
                          color: AppColors.primaryLight,
                          shape: DashedBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            width: 1,
                            color: AppColors.primary,
                            dashSize: 3,
                            dashSpacing: 2,
                          ),
                        ),
                        child: const Center(child: Image(image: AssetImage('assets/icons/image_icon.png'))),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingL),

                const _InputField(label: 'Lokatsiya', padding: true, button: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
