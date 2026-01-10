part of '../service_page.dart';

class ServiceLocationCard extends StatelessWidget {
  final String locationRegion;
  final double? latitude;
  final double? longitude;

  const ServiceLocationCard({super.key, required this.locationRegion, this.latitude, this.longitude});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border, width: .5),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border, width: .5),
            ),
            height: 160,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Image(
                image: CachedNetworkImageProvider(
                  MapsUtils.buildStaticMapUrlWithMarker(
                    center: latitude != null && longitude != null ? '$latitude,$longitude' : '39.6542,66.9597',
                    lat: 39.6542,
                    lng: 66.9597,
                    zoom: 14,
                    size: '600x300',
                    markerColor: 'red',
                  ),
                ),

                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: const Center(
                      child: Icon(IconsaxPlusLinear.location, color: AppColors.textSecondary, size: 48),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),

          Container(
            width: double.infinity,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFF5A8EF4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: const Color(0xFF1E4ED8), width: .5),
            ),
            child: Center(
              child: Text(
                'Kartada ko\'rish',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
