import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/di/injection_container.dart' as di;
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/featured_services/presentation/bloc/featured_services_bloc.dart';
import 'package:wedy/features/featured_services/presentation/bloc/featured_services_event.dart';
import 'package:wedy/features/featured_services/presentation/bloc/featured_services_state.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_event.dart';
import 'package:wedy/features/service/presentation/bloc/merchant_service_state.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/shared/widgets/primary_button.dart';

class BoostPage extends StatefulWidget {
  const BoostPage({super.key});

  @override
  State<BoostPage> createState() => _BoostPageState();
}

class _BoostPageState extends State<BoostPage> {
  int days = 30;
  static const int minDays = 1;
  static const int maxDays = 365;
  static const int basePricePerDay = 20000; // UZS
  String? _selectedServiceId;

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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    final pricePerDay = _calculatePrice();
    final totalPrice = pricePerDay * days;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.getIt<FeaturedServicesBloc>()
            ..add(const LoadFeaturedServicesEvent()),
        ),
        BlocProvider(
          create: (context) => di.getIt<MerchantServiceBloc>()
            ..add(const LoadMerchantServicesEvent()),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: BlocConsumer<FeaturedServicesBloc, FeaturedServicesState>(
            listener: (context, state) {
              if (state is FeaturedServicesLoaded &&
                  state.lastOperation is FeaturedServiceCreatedOperation) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xizmat muvaffaqiyatli reklama qilindi!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop();
              } else if (state is FeaturedServicesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, featuredState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    const WedyCircularButton(isPrimary: true),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Title
                    Text(
                      'Xizmatni reklama qilish',
                      style: AppTextStyles.headline2
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 24),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Free slots info
                    if (featuredState is FeaturedServicesLoaded)
                      _buildFreeSlotsInfo(featuredState),

                    const SizedBox(height: AppDimensions.spacingL),

                    // Service selector
                    _buildServiceSelector(),

                    const SizedBox(height: AppDimensions.spacingL),

                    // Period selector (for paid promotions)
                    _buildPeriodSelector(pricePerDay),

                    const SizedBox(height: AppDimensions.spacingL),

                    // Total price
                    Container(
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
                            'Jami narx:',
                            style: AppTextStyles.bodyRegular
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_formatPrice(totalPrice)} UZS',
                            style: AppTextStyles.headline2
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacingXL),

                    // Action buttons
                    _buildActionButtons(featuredState),

                    const SizedBox(height: AppDimensions.spacingL),

                    // Active featured services list
                    if (featuredState is FeaturedServicesLoaded &&
                        featuredState.featuredServices.isNotEmpty)
                      _buildActiveFeaturedServices(featuredState),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSlotsInfo(FeaturedServicesLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: state.hasFreeSlots ? AppColors.success : AppColors.border,
          width: 1,
        ),
        color: state.hasFreeSlots
            ? AppColors.success.withValues(alpha: 0.1)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            state.hasFreeSlots ? Icons.check_circle : Icons.info_outline,
            color: state.hasFreeSlots ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.hasFreeSlots
                      ? 'Bepul reklama mavjud!'
                      : 'Bepul reklama qolmadi',
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontWeight: FontWeight.bold,
                    color: state.hasFreeSlots
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Oylik bepul reklama: ${state.remainingFreeSlots} ta qoldi',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    return BlocBuilder<MerchantServiceBloc, MerchantServiceState>(
      builder: (context, state) {
        if (state is MerchantServiceLoaded && state.data.hasServices) {
          final services = state.data.services;

          // Auto-select first service if none selected
          if (_selectedServiceId == null && services.isNotEmpty) {
            _selectedServiceId = services.first.id;
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.border, width: .5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xizmatni tanlang',
                  style: AppTextStyles.bodyRegular
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                ...services.map((service) => RadioListTile<String>(
                      title: Text(service.name),
                      subtitle: Text(service.categoryName),
                      value: service.id,
                      groupValue: _selectedServiceId,
                      onChanged: (value) {
                        setState(() {
                          _selectedServiceId = value;
                        });
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    )),
              ],
            ),
          );
        }

        if (state is MerchantServiceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.error, width: .5),
          ),
          child: Text(
            'Avval xizmat yarating',
            style:
                AppTextStyles.bodyRegular.copyWith(color: AppColors.textError),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(int pricePerDay) {
    return Container(
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
                style: AppTextStyles.bodyRegular
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
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
                  style: AppTextStyles.bodyRegular
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
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
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
              Text(
                '$maxDays kun',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Price per day
          Text(
            '${_formatPrice(pricePerDay)} UZS/kun',
            style: AppTextStyles.bodyRegular
                .copyWith(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(FeaturedServicesState featuredState) {
    final isLoading = featuredState is FeaturedServicesLoading &&
        featuredState.type == FeaturedServicesLoadingType.creating;

    final hasFreeSlots = featuredState is FeaturedServicesLoaded &&
        featuredState.hasFreeSlots;

    return Column(
      children: [
        // Free promotion button (if slots available)
        if (hasFreeSlots)
          WedyPrimaryButton(
            label: isLoading ? 'Yuklanmoqda...' : 'Bepul reklama qilish',
            onPressed: isLoading || _selectedServiceId == null
                ? null
                : () {
                    context.read<FeaturedServicesBloc>().add(
                          CreateMonthlyFeaturedServiceEvent(_selectedServiceId!),
                        );
                  },
          ),

        if (hasFreeSlots) const SizedBox(height: AppDimensions.spacingM),

        // Paid promotion button
        WedyPrimaryButton(
          label: 'Pullik reklama qilish',
          outlined: hasFreeSlots,
          onPressed: _selectedServiceId == null
              ? null
              : () {
                  // TODO: Implement payment flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pullik reklama tez orada qo\'shiladi'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                },
        ),
      ],
    );
  }

  Widget _buildActiveFeaturedServices(FeaturedServicesLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faol reklamalar',
          style:
              AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...state.featuredServices
            .where((f) => f.isActive)
            .map((featured) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
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
                        children: [
                          Expanded(
                            child: Text(
                              featured.serviceName,
                              style: AppTextStyles.bodyRegular
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: featured.isFreeAllocation
                                  ? AppColors.success
                                  : AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Text(
                              featured.isFreeAllocation ? 'Bepul' : 'Pullik',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '${featured.daysDuration} kun • Tugaydi: ${featured.endDate.day}/${featured.endDate.month}/${featured.endDate.year}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        'Ko\'rishlar: +${featured.viewsGained} • Yoqtirishlar: +${featured.likesGained}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )),
      ],
    );
  }
}
