import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wedy/core/constants/uzbekistan_data.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_event.dart';
import 'package:wedy/features/category/presentation/bloc/category_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_event.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_state.dart';
import 'package:wedy/shared/widgets/primary_button.dart';
import 'package:widgets_easier/widgets_easier.dart';

part 'widgets/input_field.dart';

class MerchantEditPage extends StatefulWidget {
  final MerchantService? service;

  const MerchantEditPage({super.key, this.service});

  @override
  State<MerchantEditPage> createState() => _MerchantEditPageState();
}

class _MerchantEditPageState extends State<MerchantEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  XFile? pickedFile;
  List<XFile> galleryImages = [];

  bool isFixedSelected = true;
  bool isCustomSelected = false;
  bool isDailySelected = false;
  bool isHourlySelected = false;

  ServiceCategory? selectedCategory;
  String? selectedRegion;
  double? latitude;
  double? longitude;

  bool get isEditMode => widget.service != null;

  @override
  void initState() {
    super.initState();
    // Load categories first
    context.read<CategoryBloc>().add(const LoadCategoriesEvent());

    if (isEditMode) {
      final service = widget.service!;
      _nameController.text = service.name;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toStringAsFixed(0);
      selectedRegion = service.locationRegion;
      latitude = service.latitude;
      longitude = service.longitude;
      // Note: Category will be set after categories are loaded
      isFixedSelected = true; // Default, should be determined from service
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Xizmatni tahrirlash' : 'Elon yaratish', style: AppTextStyles.headline2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: BlocConsumer<MerchantServiceBloc, MerchantServiceState>(
        listener: (context, state) {
          if (state is ServiceCreated || state is ServiceUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEditMode ? 'Xizmat muvaffaqiyatli yangilandi' : 'Xizmat muvaffaqiyatli yaratildi'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is MerchantServiceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          final isLoading = state is MerchantServiceLoading;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Main image picker
                      Transform.rotate(
                        angle: 0.195,
                        child: GestureDetector(
                          onTap: isLoading ? null : () => _pickMainImage(),
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
                                      child: Image(
                                        image: AssetImage('assets/icons/image_icon.png'),
                                        width: 77,
                                        height: 77,
                                      ),
                                    )
                                  : Image(image: FileImage(File(pickedFile!.path)), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Name field
                      _InputField(
                        label: 'Nom',
                        padding: true,
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomni kiriting';
                          }
                          return null;
                        },
                      ),

                      // Description field
                      _InputField(
                        label: 'Tavsif',
                        padding: true,
                        controller: _descriptionController,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tavsifni kiriting';
                          }
                          return null;
                        },
                      ),

                      // Category dropdown
                      BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, categoryState) {
                          final categories = categoryState is CategoriesLoaded
                              ? categoryState.categories.categories
                              : <ServiceCategory>[];

                          // Initialize category from service when categories are loaded
                          if (isEditMode && selectedCategory == null && categories.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final category = categories.firstWhere(
                                (cat) => cat.id == widget.service!.categoryId,
                                orElse: () => categories.first,
                              );
                              setState(() {
                                selectedCategory = category;
                              });
                            });
                          }

                          return _InputField(
                            label: 'Kategoriya',
                            padding: true,
                            dropdown: true,
                            categories: categories,
                            selectedCategory: selectedCategory,
                            onCategoryChanged: (category) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                            validator: (value) {
                              if (selectedCategory == null) {
                                return 'Kategoriyani tanlang';
                              }
                              return null;
                            },
                          );
                        },
                      ),

                      // Region dropdown
                      _InputField(
                        label: 'Viloyat',
                        padding: true,
                        dropdown: true,
                        regions: UzbekistanData.regionNames.values.toList(),
                        selectedRegion: selectedRegion,
                        onRegionChanged: (region) {
                          setState(() {
                            selectedRegion = region;
                          });
                        },
                        validator: (value) {
                          if (selectedRegion == null || selectedRegion!.isEmpty) {
                            return 'Viloyatni tanlang';
                          }
                          return null;
                        },
                      ),

                      // Price type selector
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
                            _PriceTypeChip(
                              label: 'Aniq narx',
                              isSelected: isFixedSelected,
                              onTap: () {
                                setState(() {
                                  isFixedSelected = true;
                                  isCustomSelected = false;
                                  isDailySelected = false;
                                  isHourlySelected = false;
                                });
                              },
                            ),
                            const SizedBox(width: AppDimensions.spacingSM),
                            _PriceTypeChip(
                              label: 'Kelishamiz',
                              isSelected: isCustomSelected,
                              onTap: () {
                                setState(() {
                                  isFixedSelected = false;
                                  isCustomSelected = true;
                                  isDailySelected = false;
                                  isHourlySelected = false;
                                });
                              },
                            ),
                            const SizedBox(width: AppDimensions.spacingSM),
                            _PriceTypeChip(
                              label: 'Kunlik',
                              isSelected: isDailySelected,
                              onTap: () {
                                setState(() {
                                  isFixedSelected = false;
                                  isCustomSelected = false;
                                  isDailySelected = true;
                                  isHourlySelected = false;
                                });
                              },
                            ),
                            const SizedBox(width: AppDimensions.spacingSM),
                            _PriceTypeChip(
                              label: 'Soatlik',
                              isSelected: isHourlySelected,
                              onTap: () {
                                setState(() {
                                  isFixedSelected = false;
                                  isCustomSelected = false;
                                  isDailySelected = false;
                                  isHourlySelected = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),

                      // Price field (only if not "Kelishamiz")
                      if (!isCustomSelected)
                        _InputField(
                          label: 'Narx',
                          hasLabel: false,
                          padding: true,
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          suffix: Text('/so\'m', style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted)),
                          validator: (value) {
                            if (isCustomSelected) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Narxni kiriting';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'To\'g\'ri narx kiriting';
                            }
                            return null;
                          },
                        ),

                      // Gallery images (simplified - just show placeholder for now)
                      SizedBox(
                        height: 300,
                        child: ListView.separated(
                          separatorBuilder: (context, index) {
                            return const SizedBox(width: AppDimensions.spacingM);
                          },
                          itemCount: galleryImages.length + 1,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            if (index == galleryImages.length) {
                              return GestureDetector(
                                onTap: isLoading ? null : () => _pickGalleryImage(),
                                child: Container(
                                  width: 300,
                                  height: 300,
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? AppDimensions.spacingL : 0,
                                    right: index == galleryImages.length ? AppDimensions.spacingL : 0,
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
                                ),
                              );
                            }
                            return Container(
                              width: 300,
                              height: 300,
                              margin: EdgeInsets.only(
                                left: index == 0 ? AppDimensions.spacingL : 0,
                                right: index == galleryImages.length ? AppDimensions.spacingL : 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                image: DecorationImage(
                                  image: FileImage(File(galleryImages[index].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(IconsaxPlusLinear.close_circle, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          galleryImages.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Location button (for future geolocation)
                      _InputField(
                        label: 'Lokatsiya',
                        padding: true,
                        button: true,
                        onLocationTap: () {
                          // TODO: Implement location picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lokatsiya tanlash funksiyasi tez orada qo\'shiladi')),
                          );
                        },
                      ),

                      const SizedBox(height: AppDimensions.spacingXL),

                      // Submit button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: WedyPrimaryButton(
                          label: isEditMode ? 'Saqlash' : 'Yaratish',
                          onPressed: isLoading ? null : _handleSubmit,
                          loading: isLoading,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickMainImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        pickedFile = file;
      });
    }
  }

  Future<void> _pickGalleryImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        galleryImages.add(file);
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategoriyani tanlang')));
      return;
    }

    if (selectedRegion == null || selectedRegion!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viloyatni tanlang')));
      return;
    }

    final price = isCustomSelected ? 0.0 : double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (isEditMode) {
      // Update service
      context.read<MerchantServiceBloc>().add(
        UpdateServiceEvent(
          serviceId: widget.service!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: selectedCategory!.id,
          price: price,
          locationRegion: selectedRegion!,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } else {
      // Create service
      context.read<MerchantServiceBloc>().add(
        CreateServiceEvent(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: selectedCategory!.id,
          price: price,
          locationRegion: selectedRegion!,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
  }
}

class _PriceTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceTypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: AppDimensions.spacingS),
        margin: EdgeInsets.only(
          left: label == 'Aniq narx' ? AppDimensions.spacingL : 0,
          right: label == 'Soatlik' ? AppDimensions.spacingL : 0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD3E3FD) : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyRegular.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
