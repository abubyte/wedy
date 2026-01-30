import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/shared/widgets/section_header.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/core/utils/maps_utils.dart';
import 'package:wedy/shared/widgets/service_reviews.dart';
import '../../bloc/service_bloc.dart';
import '../../bloc/service_event.dart';
import '../../bloc/service_state.dart';
import '../../../domain/entities/service.dart';
import 'package:wedy/core/utils/deep_link_service.dart';

part 'widgets/call_button.dart';
part 'widgets/contact_tabs.dart';
part 'widgets/description.dart';
part 'widgets/gallery_items.dart';
part 'widgets/header_buttons.dart';
part 'widgets/location_card.dart';
part 'widgets/merchant_avatar.dart';
part 'widgets/meta_tile.dart';
part 'widgets/phone_tile.dart';
part 'widgets/price_button.dart';
part 'widgets/social_tile.dart';
part 'widgets/statistics_card.dart';

class WedyServicePage extends StatefulWidget {
  const WedyServicePage({super.key, this.serviceId, this.isMerchant = false});

  final String? serviceId;
  final bool isMerchant;

  @override
  State<WedyServicePage> createState() => _WedyServicePageState();
}

class _WedyServicePageState extends State<WedyServicePage> {
  bool phone = true;
  bool location = false;
  bool social = false;

  void _switchContactType(String type) {
    setState(() {
      phone = type == 'phone';
      location = type == 'location';
      social = type == 'social';
    });
  }

  @override
  void initState() {
    super.initState();
    // Service loading is now handled in build() when creating the BLoC
    // This ensures the event is dispatched before the first build
  }

  @override
  Widget build(BuildContext context) {
    // Use the global ServiceBloc instance to sync state across pages
    final globalBloc = context.read<ServiceBloc>();

    // Load service if serviceId is provided and current state doesn't have it
    if (widget.serviceId != null) {
      final currentState = globalBloc.state;
      final hasService = currentState is ServicesLoaded && currentState.currentServiceDetails?.id == widget.serviceId;

      if (!hasService && currentState is! ServiceLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final state = globalBloc.state;
            final hasCurrentService = state is ServicesLoaded && state.currentServiceDetails?.id == widget.serviceId;
            if (!hasCurrentService && state is! ServiceLoading) {
              globalBloc.add(LoadServiceByIdEvent(widget.serviceId!));
            }
          }
        });
      }
    }

    return BlocProvider.value(
      value: globalBloc,
      child: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is ServiceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
          // Note: ServiceInteractionSuccess is no longer emitted to avoid state replacement
          // The UI updates optimistically, so no success message needed
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            // Show loading if we're loading or if we have a serviceId but haven't loaded yet (initial state)
            if (state is ServiceLoading ||
                (state is ServicesLoaded && state.currentServiceDetails == null && widget.serviceId != null) ||
                (state is ServiceInitial && widget.serviceId != null)) {
              return Scaffold(
                appBar: AppBar(title: const Text('Yuklanmoqda...')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is ServiceError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Xatolik')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.serviceId != null) {
                            context.read<ServiceBloc>().add(LoadServiceByIdEvent(widget.serviceId!));
                          }
                        },
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final service = state is ServicesLoaded ? state.currentServiceDetails : null;

            // Show "not found" only if we don't have a serviceId (invalid route)
            // or if we've finished loading (not initial) and got no service
            if (service == null) {
              // If we have a serviceId but no service, and we're not in initial state, show not found
              if (widget.serviceId != null && state is! ServiceInitial && state is ServicesLoaded) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Xizmat topilmadi')),
                  body: const Center(child: Text('Xizmat ma\'lumotlari topilmadi')),
                );
              }
              // If no serviceId provided, show not found
              if (widget.serviceId == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Xizmat topilmadi')),
                  body: const Center(child: Text('Xizmat ma\'lumotlari topilmadi')),
                );
              }
              // Otherwise, still loading (shouldn't reach here, but just in case)
              return Scaffold(
                appBar: AppBar(title: const Text('Yuklanmoqda...')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              bottomNavigationBar: widget.isMerchant ? null : const CallButton(),
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: ServiceHeaderButtons(isMerchant: widget.isMerchant, service: service),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Thumbnail
                      ServiceMerchantAvatar(merchant: service.merchant),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: Text(service.name, style: AppTextStyles.headline2, maxLines: 3),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),

                      // Username
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: Text(
                          service.merchant.businessName,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),

                      // Region & Category
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: ServiceMetaTile(
                          locationRegion: service.locationRegion,
                          categoryName: service.categoryName,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Price
                      ServicePriceButton(price: service.price, priceType: service.priceType ?? 'fixed'),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Gallery Items
                      if (service.images.isNotEmpty) ...[
                        const SectionHeader(title: 'Galareya', hasAction: false, applyPadding: true),
                        const SizedBox(height: AppDimensions.spacingS),
                        ServiceGalleryItems(images: service.images),
                        const SizedBox(height: AppDimensions.spacingM),
                      ],

                      // Description
                      ServiceDescription(description: service.description),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Statistics
                      const SectionHeader(title: 'Statistika', hasAction: false, applyPadding: true),
                      const SizedBox(height: AppDimensions.spacingL),
                      ServiceStatisticsCard(
                        viewCount: service.viewCount,
                        likeCount: service.likeCount,
                        saveCount: service.saveCount,
                        shareCount: service.shareCount,
                        rating: service.overallRating,
                        reviewCount: service.totalReviews,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Contact Tabs
                      ServiceContactTabs(
                        isPhoneSelected: phone,
                        isLocationSelected: location,
                        isSocialSelected: social,
                        onPhoneTap: () => _switchContactType('phone'),
                        onLocationTap: () => _switchContactType('location'),
                        onSocialTap: () => _switchContactType('social'),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),

                      // Phone Numbers
                      if (phone) ...[
                        if (service.phoneContacts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                            child: Text(
                              'Telefon raqamlar mavjud emas',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        else
                          ...service.phoneContacts.map(
                            (contact) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                              child: ServicePhoneTile(phoneNumber: contact.contactValue),
                            ),
                          ),
                      ],

                      // Location
                      if (location)
                        ServiceLocationCard(
                          locationRegion: service.locationRegion,
                          latitude: service.latitude,
                          longitude: service.longitude,
                        ),

                      // Social
                      if (social) ...[
                        if (service.socialMediaContacts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                            child: Text(
                              'Ijtimoiy tarmoqlar mavjud emas',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        else
                          ...service.socialMediaContacts.map(
                            (contact) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                              child: ServiceSocialTile(url: contact.contactValue, platformName: contact.platformName),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppDimensions.spacingL),

                      // Reviews
                      SectionHeader(
                        title: 'Fikrlar',
                        applyPadding: true,
                        hasAction: true,
                        onTap: () => context.pushNamed(RouteNames.reviews, pathParameters: {'serviceId': service.id}),
                      ),
                      const SizedBox(height: AppDimensions.spacingSM),
                      ServiceReviews(serviceId: service.id),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
