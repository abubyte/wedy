import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/apps/client/widgets/section_header.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/core/utils/maps_utils.dart';

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
part 'widgets/service_reviews.dart';
part 'widgets/social_tile.dart';
part 'widgets/statistics_card.dart';

class ClientServicePage extends StatefulWidget {
  const ClientServicePage({super.key});

  @override
  State<ClientServicePage> createState() => _ClientServicePageState();
}

class _ClientServicePageState extends State<ClientServicePage> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CallButton(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                child: ServiceHeaderButtons(),
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Thumbnail
              const ServiceMerchantAvatar(),
              const SizedBox(height: AppDimensions.spacingL),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                child: Text('Sam Decor uz Dekoratsiya', style: AppTextStyles.headline2, maxLines: 3),
              ),
              const SizedBox(height: AppDimensions.spacingXS),

              // Username
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                child: Text(
                  '@sam_decor_uz',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),

              // Region & Category
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                child: ServiceMetaTile(),
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Price
              const ServicePriceButton(),
              const SizedBox(height: AppDimensions.spacingL),

              // Gallery Items
              const ClientSectionHeader(title: 'Galareya', hasAction: false, applyPadding: true),
              const SizedBox(height: AppDimensions.spacingS),
              const ServiceGalleryItems(),
              const SizedBox(height: AppDimensions.spacingM),

              // Description
              const ServiceDescription(),
              const SizedBox(height: AppDimensions.spacingL),

              // Statistics
              const ClientSectionHeader(title: 'Statistika', hasAction: false, applyPadding: true),

              const SizedBox(height: AppDimensions.spacingL),
              const ServiceStatisticsCard(),
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
                const ServicePhoneTile(),
                const SizedBox(height: AppDimensions.spacingS),

                const ServicePhoneTile(),
                const SizedBox(height: AppDimensions.spacingS),

                const ServicePhoneTile(),
              ],

              // Location
              if (location) const ServiceLocationCard(),

              // Social
              if (social) ...[
                const ServiceSocialTile(),
                const SizedBox(height: AppDimensions.spacingS),

                const ServiceSocialTile(),
              ],
              const SizedBox(height: AppDimensions.spacingL),

              // Reviews
              const ClientSectionHeader(title: 'Fikrlar', applyPadding: true),
              const SizedBox(height: AppDimensions.spacingSM),
              const ServiceReviews(),
              const SizedBox(height: AppDimensions.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}
