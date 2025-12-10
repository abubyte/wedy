import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_event.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/empty_state.dart';
import 'package:wedy/shared/widgets/primary_button.dart';
import 'package:wedy/shared/widgets/section_header.dart';
import 'package:wedy/shared/widgets/service_reviews.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<MerchantServiceBloc>().add(const LoadMerchantServicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<MerchantServiceBloc, MerchantServiceState>(
        listener: (context, state) {
          if (state is ServiceCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xizmat muvaffaqiyatli yaratildi'), backgroundColor: AppColors.success),
            );
            // Service list will be automatically reloaded by the bloc
          } else if (state is ServiceUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xizmat muvaffaqiyatli yangilandi'), backgroundColor: AppColors.success),
            );
            // Service list will be automatically reloaded by the bloc
          } else if (state is ServiceDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xizmat muvaffaqiyatli o\'chirildi'), backgroundColor: AppColors.success),
            );
            // Service list will be automatically reloaded by the bloc
          } else if (state is MerchantServiceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          if (state is MerchantServiceLoading || state is MerchantServiceInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MerchantServicesLoaded) {
            final services = state.servicesResponse.services;

            // Show empty state if no services
            if (services.isEmpty) {
              return _buildEmptyState();
            }

            // Show first service (only one service per merchant for this release)
            final service = services.first;
            return _buildServiceProfile(service);
          } else if (state is ServiceCreated || state is ServiceUpdated) {
            // Show loading while services are being reloaded after create/update
            return const Center(child: CircularProgressIndicator());
          } else if (state is MerchantServiceError) {
            return _buildErrorState(state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppDimensions.spacingXL),
            const WedyEmptyState(
              title: 'Xizmat yo\'q',
              subtitle: 'Hozircha sizda xizmat mavjud emas. Yangi xizmat qo\'shish uchun quyidagi tugmani bosing.',
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            WedyPrimaryButton(label: 'Yangi xizmat qo\'shish', onPressed: () => context.pushNamed(RouteNames.edit)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppDimensions.spacingL),
              WedyPrimaryButton(
                label: 'Qayta urinish',
                onPressed: () {
                  context.read<MerchantServiceBloc>().add(const LoadMerchantServicesEvent());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceProfile(service) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button, service image, and edit buttons
            _buildHeader(service),

            // Service title and category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(service.name, style: AppTextStyles.headline1.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(service.categoryName, style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: AppDimensions.spacingM),

                  // Price button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: Text(
                      '${_formatPrice(service.price)} so\'m/kun',
                      style: AppTextStyles.bodyRegular.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                ],
              ),
            ),

            // Gallery section
            _buildGallerySection(service),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spacingL),
                  Text(
                    service.description,
                    style: AppTextStyles.bodyRegular,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                ],
              ),
            ),

            // Statistics
            _buildStatistics(service),

            // Share button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
              child: WedyPrimaryButton(
                label: 'Ulashish',
                icon: const Icon(IconsaxPlusLinear.export, size: 20),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ),

            const SizedBox(height: AppDimensions.spacingL),

            // Contact buttons
            _buildContactButtons(),

            const SizedBox(height: AppDimensions.spacingL),

            // Reviews section
            ServiceReviews(serviceId: service.id, vertical: false, showHeader: true),

            const SizedBox(height: AppDimensions.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(service) {
    return Stack(
      children: [
        // Service main image
        if (service.mainImageUrl != null)
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: service.mainImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surface,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface,
                child: const Icon(IconsaxPlusLinear.image, size: 48, color: AppColors.textMuted),
              ),
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            color: AppColors.surface,
            child: const Icon(IconsaxPlusLinear.image, size: 48, color: AppColors.textMuted),
          ),

        // Header buttons
        Positioned(
          top: AppDimensions.spacingM,
          left: AppDimensions.spacingM,
          child: WedyCircularButton(
            icon: IconsaxPlusLinear.share,
            onTap: () {
              // TODO: Implement share
            },
          ),
        ),
        Positioned(
          top: AppDimensions.spacingM,
          right: AppDimensions.spacingM,
          child: Row(
            children: [
              WedyCircularButton(
                icon: IconsaxPlusLinear.edit_2,
                onTap: () => context.pushNamed(RouteNames.edit, extra: service),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              WedyCircularButton(icon: IconsaxPlusLinear.trash, onTap: () => _showDeleteDialog(context, service)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection(service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: SectionHeader(
            title: 'Galereya',
            onTap: () {
              // TODO: Navigate to full gallery
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            itemCount: 1, // For now, just show main image
            itemBuilder: (context, index) {
              if (service.mainImageUrl != null) {
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    color: AppColors.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    child: CachedNetworkImage(
                      imageUrl: service.mainImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surface,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surface,
                        child: const Icon(IconsaxPlusLinear.image, size: 48, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: AppDimensions.spacingM),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  color: AppColors.surface,
                ),
                child: const Icon(IconsaxPlusLinear.image, size: 48, color: AppColors.textMuted),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Statistika'),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              _buildStatItem(IconsaxPlusLinear.star, '${service.overallRating.toStringAsFixed(1)}'),
              const SizedBox(width: AppDimensions.spacingXL),
              _buildStatItem(IconsaxPlusLinear.eye, _formatNumber(service.viewCount)),
              const SizedBox(width: AppDimensions.spacingXL),
              _buildStatItem(IconsaxPlusLinear.message, '${service.totalReviews}'),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXL),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textPrimary),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(value, style: AppTextStyles.bodyRegular),
      ],
    );
  }

  Widget _buildContactButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: Row(
        children: [
          Expanded(
            child: _buildContactButton('Telefon', IconsaxPlusLinear.call, () {
              // TODO: Implement phone call
            }),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: _buildContactButton('Manzil', IconsaxPlusLinear.location, () {
              // TODO: Implement location
            }, isSelected: true),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: _buildContactButton('Ijtimoiy tarmoqlar', IconsaxPlusLinear.share, () {
              // TODO: Show social media
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(String label, IconData icon, VoidCallback onTap, {bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: AppDimensions.spacingXS),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  void _showDeleteDialog(BuildContext context, service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xizmatni o\'chirish'),
        content: Text('${service.name} xizmatini o\'chirishni xohlaysizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<MerchantServiceBloc>().add(DeleteServiceEvent(service.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}
