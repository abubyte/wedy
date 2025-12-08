import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_event.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/empty_state.dart';
import 'package:wedy/shared/widgets/primary_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MerchantServicesPage extends StatefulWidget {
  const MerchantServicesPage({super.key});

  @override
  State<MerchantServicesPage> createState() => _MerchantServicesPageState();
}

class _MerchantServicesPageState extends State<MerchantServicesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MerchantServiceBloc>().add(const LoadMerchantServicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mening xizmatlarim', style: AppTextStyles.headline2),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(IconsaxPlusLinear.add), onPressed: () => context.pushNamed(RouteNames.edit)),
        ],
      ),
      body: BlocConsumer<MerchantServiceBloc, MerchantServiceState>(
        listener: (context, state) {
          if (state is MerchantServiceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          } else if (state is ServiceDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xizmat muvaffaqiyatli o\'chirildi'), backgroundColor: AppColors.success),
            );
          }
        },
        builder: (context, state) {
          if (state is MerchantServiceLoading || state is MerchantServiceInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MerchantServicesLoaded) {
            final services = state.servicesResponse.services;
            if (services.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const WedyEmptyState(
                        title: 'Xizmatlar yo\'q',
                        subtitle:
                            'Hozircha sizda xizmatlar mavjud emas. Yangi xizmat qo\'shish uchun quyidagi tugmani bosing.',
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      WedyPrimaryButton(
                        label: 'Yangi xizmat qo\'shish',
                        onPressed: () => context.pushNamed(RouteNames.edit),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<MerchantServiceBloc>().add(const RefreshMerchantServicesEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceCard(
                    service: service,
                    onTap: () => context.pushNamed(RouteNames.edit, extra: service),
                    onDelete: () => _showDeleteDialog(context, service),
                  );
                },
              ),
            );
          } else if (state is MerchantServiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppDimensions.spacingL),
                  WedyPrimaryButton(
                    label: 'Qayta urinish',
                    onPressed: () {
                      context.read<MerchantServiceBloc>().add(const LoadMerchantServicesEvent());
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.edit),
        backgroundColor: AppColors.primary,
        child: const Icon(IconsaxPlusLinear.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MerchantService service) {
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

class _ServiceCard extends StatelessWidget {
  final MerchantService service;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ServiceCard({required this.service, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Row(
            children: [
              // Service image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: service.mainImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: service.mainImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surface,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surface,
                          child: const Icon(IconsaxPlusLinear.image),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surface,
                        child: const Icon(IconsaxPlusLinear.image),
                      ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(service.categoryName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Row(
                      children: [
                        Text(
                          '${service.price.toStringAsFixed(0)} so\'m',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: 2),
                          decoration: BoxDecoration(
                            color: service.isActive ? AppColors.success : AppColors.error,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Text(
                            service.isActive ? 'Faol' : 'Nofaol',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
