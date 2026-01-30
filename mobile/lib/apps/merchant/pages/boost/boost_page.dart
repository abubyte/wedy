import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/apps/merchant/pages/boost/payment_method_page.dart';
import 'package:wedy/apps/merchant/pages/boost/promotion_details_sheet.dart';
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

  // Discount tiers
  static const List<_DiscountTier> discountTiers = [
    _DiscountTier(minDays: 1, maxDays: 7, discount: 0, pricePerDay: 20000),
    _DiscountTier(minDays: 8, maxDays: 30, discount: 10, pricePerDay: 18000),
    _DiscountTier(minDays: 31, maxDays: 90, discount: 20, pricePerDay: 16000),
    _DiscountTier(minDays: 91, maxDays: 365, discount: 30, pricePerDay: 14000),
  ];

  _DiscountTier get _currentTier {
    for (final tier in discountTiers) {
      if (days >= tier.minDays && days <= tier.maxDays) {
        return tier;
      }
    }
    return discountTiers.last;
  }

  int get _pricePerDay => _currentTier.pricePerDay;
  int get _discount => _currentTier.discount;
  int get _totalPrice => _pricePerDay * days;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.getIt<FeaturedServicesBloc>()..add(const LoadFeaturedServicesEvent())),
        BlocProvider(create: (context) => di.getIt<MerchantServiceBloc>()..add(const LoadMerchantServicesEvent())),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: BlocConsumer<FeaturedServicesBloc, FeaturedServicesState>(
            listener: (context, state) {
              if (state is FeaturedServicesLoaded && state.lastOperation is FeaturedServiceCreatedOperation) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xizmat muvaffaqiyatli reklama qilindi!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop();
              } else if (state is FeaturedServicesError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
              }
            },
            builder: (context, featuredState) {
              return Column(
                children: [
                  Expanded(
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
                            style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
                          ),
                          const SizedBox(height: AppDimensions.spacingXL),

                          // Service selector
                          _buildServiceSelector(),
                          const SizedBox(height: AppDimensions.spacingL),

                          // Days selector with slider
                          _buildDaysSelector(),
                          const SizedBox(height: AppDimensions.spacingL),

                          // Discount tiers
                          _buildDiscountTiers(),
                          const SizedBox(height: AppDimensions.spacingL),

                          // Current selection info
                          _buildSelectionInfo(),
                          const SizedBox(height: AppDimensions.spacingL),

                          // Total price
                          _buildTotalPrice(),
                          const SizedBox(height: AppDimensions.spacingL),

                          // Free slots info and button
                          if (featuredState is FeaturedServicesLoaded) _buildFreeSlotsSection(context, featuredState),

                          const SizedBox(height: AppDimensions.spacingL),

                          // Active featured services
                          if (featuredState is FeaturedServicesLoaded && featuredState.featuredServices.isNotEmpty)
                            _buildActiveFeaturedServices(featuredState),
                        ],
                      ),
                    ),
                  ),

                  // Bottom button
                  _buildBottomButton(context, featuredState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSelector() {
    return BlocBuilder<MerchantServiceBloc, MerchantServiceState>(
      builder: (context, state) {
        if (state is MerchantServiceLoaded && state.data.hasServices) {
          final services = state.data.services;

          if (_selectedServiceId == null && services.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedServiceId = services.first.id;
                });
              }
            });
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: AppDimensions.spacingS),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedServiceId,
                isExpanded: true,
                hint: const Text('Xizmatni tanlang'),
                items: services.map((service) {
                  return DropdownMenuItem<String>(value: service.id, child: Text(service.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceId = value;
                  });
                },
              ),
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
            border: Border.all(color: AppColors.error, width: 1),
          ),
          child: Text('Avval xizmat yarating', style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textError)),
        );
      },
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kunlar soni', style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  color: AppColors.primaryLight,
                ),
                child: Text(days.toString(), style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            '${_formatPrice(basePricePerDay)} UZS/kun',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 6,
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
              Text('$minDays kun', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12)),
              Text('$maxDays kun', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountTiers() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTierCard(discountTiers[0])),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(child: _buildTierCard(discountTiers[1])),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          children: [
            Expanded(child: _buildTierCard(discountTiers[2])),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(child: _buildTierCard(discountTiers[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildTierCard(_DiscountTier tier) {
    final isActive = _currentTier == tier;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: isActive ? 2 : 1),
        color: isActive ? AppColors.primaryLight : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tier.minDays}-${tier.maxDays} kun',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tier.discount}%',
                style: AppTextStyles.headline2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text(_formatPrice(tier.pricePerDay), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        color: AppColors.surfaceMuted,
      ),
      child: Column(
        children: [
          _buildInfoRow('1kunlik narx:', '${_formatPrice(_pricePerDay)} UZS'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildInfoRow('Tanlangan kunlar:', '$days kun'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildInfoRow('Chegirma:', '$_discount%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        Text(value, style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTotalPrice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Jami narx:', style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w500)),
          Text(
            '${_formatPrice(_totalPrice)} so\'m',
            style: AppTextStyles.headline2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeSlotsSection(BuildContext context, FeaturedServicesLoaded state) {
    if (!state.hasFreeSlots) return const SizedBox.shrink();

    final isLoading = context.watch<FeaturedServicesBloc>().state is FeaturedServicesLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.success, width: 1),
        color: AppColors.success.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: AppColors.success),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'Bepul reklama mavjud!',
                style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'Oylik bepul reklama: ${state.remainingFreeSlots} ta qoldi',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SizedBox(
            width: double.infinity,
            child: WedyPrimaryButton(
              label: isLoading ? 'Yuklanmoqda...' : 'Bepul reklama qilish',
              onPressed: isLoading || _selectedServiceId == null
                  ? null
                  : () {
                      context.read<FeaturedServicesBloc>().add(CreateMonthlyFeaturedServiceEvent(_selectedServiceId!));
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFeaturedServices(FeaturedServicesLoaded state) {
    final activeServices = state.featuredServices.where((f) => f.isActive).toList();
    if (activeServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Faol reklamalar', style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
        const SizedBox(height: AppDimensions.spacingM),
        ...activeServices.map(
          (featured) => GestureDetector(
            onTap: () => PromotionDetailsSheet.show(context, featured),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featured.serviceName,
                          style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          '${featured.daysDuration} kun • Tugaydi: ${featured.endDate.day}/${featured.endDate.month}/${featured.endDate.year}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS, vertical: 4),
                    decoration: BoxDecoration(
                      color: featured.isFreeAllocation ? AppColors.success : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      featured.isFreeAllocation ? 'Bepul' : 'Pullik',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, FeaturedServicesState featuredState) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: WedyPrimaryButton(
          label: 'Davom etish',
          icon: const Icon(Icons.arrow_forward),
          onPressed: _selectedServiceId == null ? null : () => _navigateToPaymentMethod(context),
        ),
      ),
    );
  }

  void _navigateToPaymentMethod(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FeaturedServicesBloc>(),
          child: PaymentMethodPage(serviceId: _selectedServiceId!, durationDays: days, totalPrice: _totalPrice),
        ),
      ),
    );
  }
}

class _DiscountTier {
  final int minDays;
  final int maxDays;
  final int discount;
  final int pricePerDay;

  const _DiscountTier({
    required this.minDays,
    required this.maxDays,
    required this.discount,
    required this.pricePerDay,
  });
}
