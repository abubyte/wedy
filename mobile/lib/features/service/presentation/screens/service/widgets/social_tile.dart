part of '../service_page.dart';

class ServiceSocialTile extends StatelessWidget {
  const ServiceSocialTile({super.key, required this.url, this.platformName});

  final String url;
  final String? platformName;

  IconData _getPlatformIcon() {
    final platform = platformName?.toLowerCase() ?? '';
    if (platform.contains('telegram') || url.contains('t.me')) {
      return IconsaxPlusLinear.send_2;
    } else if (platform.contains('instagram') || url.contains('instagram')) {
      return IconsaxPlusLinear.instagram;
    } else if (platform.contains('facebook') || url.contains('facebook')) {
      return IconsaxPlusLinear.people;
    } else if (platform.contains('youtube') || url.contains('youtube')) {
      return IconsaxPlusLinear.video_play;
    } else if (platform.contains('twitter') ||
        platform.contains('x.com') ||
        url.contains('twitter') ||
        url.contains('x.com')) {
      return IconsaxPlusLinear.message;
    } else if (platform.contains('tiktok') || url.contains('tiktok')) {
      return IconsaxPlusLinear.music;
    } else if (platform.contains('website') || platform.contains('web')) {
      return IconsaxPlusLinear.global;
    }
    return IconsaxPlusLinear.link;
  }

  String _getDisplayName() {
    if (platformName != null && platformName!.isNotEmpty) {
      return platformName!;
    }
    // Extract platform name from URL
    if (url.contains('t.me') || url.contains('telegram')) return 'Telegram';
    if (url.contains('instagram')) return 'Instagram';
    if (url.contains('facebook')) return 'Facebook';
    if (url.contains('youtube')) return 'YouTube';
    if (url.contains('twitter') || url.contains('x.com')) return 'X (Twitter)';
    if (url.contains('tiktok')) return 'TikTok';
    return 'Ijtimoiy tarmoq';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(url));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS, horizontal: AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_getPlatformIcon(), size: 24, color: Colors.black),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                _getDisplayName(),
                style: AppTextStyles.bodyRegular.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
