// ignore_for_file: use_build_context_synchronously

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
import 'package:wedy/core/di/injection_container.dart' as di;
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_event.dart';
import 'package:wedy/features/category/presentation/bloc/category_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_event.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_state.dart';
import 'package:wedy/shared/widgets/primary_button.dart';
import 'package:widgets_easier/widgets_easier.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

part 'widgets/input_field.dart';

class _ContactItem {
  final String value;
  final String? platformName;

  _ContactItem({required this.value, this.platformName});
}

class MerchantEditPage extends StatefulWidget {
  final MerchantService? service;

  const MerchantEditPage({super.key, this.service});

  @override
  State<MerchantEditPage> createState() => _MerchantEditPageState();
}

class _MerchantEditPageState extends State<MerchantEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
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

  // Contact management
  List<_ContactItem> phoneContacts = [];
  List<_ContactItem> socialContacts = [];

  bool get isEditMode => widget.service != null;

  ServiceRepository get _serviceRepository => di.getIt<ServiceRepository>();

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
        title: Text(
          isEditMode ? 'Xizmatni tahrirlash' : 'Elon yaratish',
          style: AppTextStyles.headline2,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: BlocConsumer<MerchantServiceBloc, MerchantServiceState>(
        listener: (context, state) async {
          if (state is MerchantServiceLoaded) {
            final operation = state.data.lastOperation;
            if (operation is ServiceCreatedOperation) {
              // Upload images after service creation
              await _uploadImages(operation.service.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xizmat muvaffaqiyatli yaratildi'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop();
              }
            } else if (operation is ServiceUpdatedOperation) {
              // Upload images after service update
              await _uploadImages(operation.service.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xizmat muvaffaqiyatli yangilandi'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop();
              }
            }
          } else if (state is MerchantServiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is MerchantServiceLoading;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingL,
                  ),
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
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusL,
                                ),
                                width: 1,
                                color: AppColors.primary,
                                dashSize: 3,
                                dashSpacing: pickedFile?.path == null ? 2 : 0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusL,
                              ),
                              child: pickedFile?.path == null
                                  ? const Center(
                                      child: Image(
                                        image: AssetImage(
                                          'assets/icons/image_icon.png',
                                        ),
                                        width: 77,
                                        height: 77,
                                      ),
                                    )
                                  : Image(
                                      image: FileImage(File(pickedFile!.path)),
                                      fit: BoxFit.cover,
                                    ),
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

                      // Name field
                      _InputField(
                        label: 'Foydalanuvchi nomi',
                        padding: true,
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Foydalanuvchi nomini kiriting';
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
                          if (isEditMode &&
                              selectedCategory == null &&
                              categories.isNotEmpty) {
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
                          if (selectedRegion == null ||
                              selectedRegion!.isEmpty) {
                            return 'Viloyatni tanlang';
                          }
                          return null;
                        },
                      ),

                      // Price type selector
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingL,
                        ),
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
                          suffix: Text(
                            '/so\'m',
                            style: AppTextStyles.bodyRegular.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
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
                            return const SizedBox(
                              width: AppDimensions.spacingM,
                            );
                          },
                          itemCount: galleryImages.length + 1,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            if (index == galleryImages.length) {
                              return GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () => _pickGalleryImage(),
                                child: Container(
                                  width: 300,
                                  height: 300,
                                  margin: EdgeInsets.only(
                                    left: index == 0
                                        ? AppDimensions.spacingL
                                        : 0,
                                    right: index == galleryImages.length
                                        ? AppDimensions.spacingL
                                        : 0,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: AppColors.primaryLight,
                                    shape: DashedBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusL,
                                      ),
                                      width: 1,
                                      color: AppColors.primary,
                                      dashSize: 3,
                                      dashSpacing: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Image(
                                      image: AssetImage(
                                        'assets/icons/image_icon.png',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              width: 300,
                              height: 300,
                              margin: EdgeInsets.only(
                                left: index == 0 ? AppDimensions.spacingL : 0,
                                right: index == galleryImages.length
                                    ? AppDimensions.spacingL
                                    : 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusL,
                                ),
                                image: DecorationImage(
                                  image: FileImage(
                                    File(galleryImages[index].path),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(
                                        IconsaxPlusLinear.close_circle,
                                        color: Colors.white,
                                      ),
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
                            const SnackBar(
                              content: Text(
                                'Lokatsiya tanlash funksiyasi tez orada qo\'shiladi',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppDimensions.spacingL),

                      // Phone contacts section
                      _buildContactsSection(
                        title: 'Telefon raqamlar',
                        contacts: phoneContacts,
                        isPhone: true,
                        isLoading: isLoading,
                        onAdd: () => _showAddContactDialog(isPhone: true),
                        onDelete: (index) {
                          setState(() {
                            phoneContacts.removeAt(index);
                          });
                        },
                      ),

                      const SizedBox(height: AppDimensions.spacingL),

                      // Social media contacts section
                      _buildContactsSection(
                        title: 'Ijtimoiy tarmoqlar',
                        contacts: socialContacts,
                        isPhone: false,
                        isLoading: isLoading,
                        onAdd: () => _showAddContactDialog(isPhone: false),
                        onDelete: (index) {
                          setState(() {
                            socialContacts.removeAt(index);
                          });
                        },
                      ),

                      const SizedBox(height: AppDimensions.spacingXL),

                      // Submit button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingL,
                        ),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategoriyani tanlang')));
      return;
    }

    if (selectedRegion == null || selectedRegion!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Viloyatni tanlang')));
      return;
    }

    final price = isCustomSelected
        ? 0.0
        : double.tryParse(_priceController.text.trim()) ?? 0.0;

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

    // Save contacts after service is created/updated
    await _saveContacts();
  }

  Widget _buildContactsSection({
    required String title,
    required List<_ContactItem> contacts,
    required bool isPhone,
    required VoidCallback onAdd,
    required Function(int) onDelete,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onAdd,
                icon: const Icon(IconsaxPlusLinear.add, size: 16),
                label: const Text('Qo\'shish'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          if (contacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                'Hozircha kontaktlar yo\'q',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ...contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.value, style: AppTextStyles.bodyRegular),
                          if (contact.platformName != null &&
                              contact.platformName!.isNotEmpty)
                            Text(
                              contact.platformName!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        IconsaxPlusLinear.trash,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: isLoading ? null : () => onDelete(index),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddContactDialog({required bool isPhone}) {
    final contactController = TextEditingController();
    String? selectedPlatform;

    final platforms = [
      'Telegram',
      'Instagram',
      'Facebook',
      'YouTube',
      'TikTok',
      'LinkedIn',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isPhone ? 'Telefon raqam qo\'shish' : 'Ijtimoiy tarmoq qo\'shish',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPhone)
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon raqam',
                      hintText: '901234567',
                      prefixText: '+998 ',
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlatform,
                    decoration: const InputDecoration(
                      labelText: 'Platforma',
                      hintText: 'Platformani tanlang',
                    ),
                    items: platforms.map((platform) {
                      return DropdownMenuItem(
                        value: platform,
                        child: Text(platform),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPlatform = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL yoki username',
                      hintText: 'https://t.me/username yoki @username',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () {
                final value = contactController.text.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Qiymatni kiriting')),
                  );
                  return;
                }
                if (!isPhone && selectedPlatform == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Platformani tanlang')),
                  );
                  return;
                }

                setState(() {
                  if (isPhone) {
                    phoneContacts.add(
                      _ContactItem(value: value, platformName: null),
                    );
                  } else {
                    socialContacts.add(
                      _ContactItem(
                        value: value,
                        platformName: selectedPlatform,
                      ),
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContacts() async {
    try {
      final dio = ApiClient.instance;

      // Save phone contacts
      for (final contact in phoneContacts) {
        await dio.post(
          '${ApiConstants.apiVersion}/merchants/contacts',
          data: {
            'contact_type': 'phone',
            'contact_value': contact.value,
            'display_order': phoneContacts.indexOf(contact),
          },
        );
      }

      // Save social media contacts
      for (final contact in socialContacts) {
        await dio.post(
          '${ApiConstants.apiVersion}/merchants/contacts',
          data: {
            'contact_type': 'social_media',
            'contact_value': contact.value,
            'platform_name': contact.platformName,
            'display_order': socialContacts.indexOf(contact),
          },
        );
      }
    } catch (e) {
      // Handle error silently or show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kontaktlarni saqlashda xatolik: $e')),
        );
      }
    }
  }

  Future<void> _uploadImages(String serviceId) async {
    try {
      // Upload main image first (display_order = 0)
      if (pickedFile != null) {
        final contentType = _getContentType(pickedFile!.path);
        final fileName = pickedFile!.path.split('/').last;
        final result = await _serviceRepository.uploadServiceImage(
          serviceId: serviceId,
          imagePath: pickedFile!.path,
          fileName: fileName,
          contentType: contentType,
          displayOrder: 0,
        );
        result.fold((failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Asosiy rasm yuklashda xatolik: ${failure.toString()}',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }, (_) {});
      }

      // Upload gallery images
      for (int i = 0; i < galleryImages.length; i++) {
        final image = galleryImages[i];
        final contentType = _getContentType(image.path);
        final fileName = image.path.split('/').last;
        final result = await _serviceRepository.uploadServiceImage(
          serviceId: serviceId,
          imagePath: image.path,
          fileName: fileName,
          contentType: contentType,
          displayOrder: i + 1, // Start from 1 since main image is 0
        );
        result.fold((failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rasm yuklashda xatolik: ${failure.toString()}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }, (_) {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasmlarni yuklashda xatolik: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

class _PriceTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
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
          style: AppTextStyles.bodyRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
