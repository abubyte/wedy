import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/navigation/route_names.dart';

/// Service for handling deep links and sharing
class DeepLinkService {
  static const String _baseUrl = 'wedy://service';
  static const String _webBaseUrl = 'https://wedy.uz/service'; // Replace with your actual web domain

  final AppLinks _appLinks = AppLinks();

  /// Generate deep link URL for a service
  String generateServiceDeepLink(String serviceId, {bool useWebUrl = false}) {
    final baseUrl = useWebUrl ? _webBaseUrl : _baseUrl;
    return '$baseUrl?id=$serviceId';
  }

  /// Share service with deep link
  Future<void> shareService({
    required String serviceId,
    required String serviceName,
    String? description,
    bool useWebUrl = false,
  }) async {
    // Generate both web URL and app scheme
    final webUrl = generateServiceDeepLink(serviceId, useWebUrl: true);
    final appScheme = generateServiceDeepLink(serviceId, useWebUrl: false);

    // Use web URL for sharing (Universal Links will open app if installed)
    // Also include app scheme as fallback
    final text = description != null && description.isNotEmpty
        ? '$serviceName\n\n$description\n\n$webUrl\n\nYoki app\'da ochish: $appScheme'
        : '$serviceName\n\n$webUrl\n\nYoki app\'da ochish: $appScheme';

    await Share.share(text, subject: serviceName);
  }

  /// Listen to incoming deep links
  Stream<String> get deepLinkStream {
    return _appLinks.uriLinkStream.map((uri) => uri.toString());
  }

  /// Get initial deep link (if app was opened via deep link)
  Future<String?> getInitialDeepLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      return uri?.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting initial deep link: $e');
      }
      return null;
    }
  }

  /// Parse service ID from deep link
  String? parseServiceIdFromDeepLink(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);

      // Handle both app scheme (wedy://service?id=...) and web URL (https://wedy.uz/service?id=...)
      if (uri.scheme == 'wedy' || uri.host.contains('wedy')) {
        final path = uri.path;
        if (path.contains('/service') || path == '/service') {
          return uri.queryParameters['id'];
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing deep link: $e');
      }
      return null;
    }
  }

  /// Check if deep link is a service link
  bool isServiceDeepLink(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      final path = uri.path;
      return (uri.scheme == 'wedy' || uri.host.contains('wedy')) && (path.contains('/service') || path == '/service');
    } catch (e) {
      return false;
    }
  }

  /// Convert deep link to app route
  String? deepLinkToRoute(String deepLink) {
    if (!isServiceDeepLink(deepLink)) {
      return null;
    }

    final serviceId = parseServiceIdFromDeepLink(deepLink);
    if (serviceId == null || serviceId.isEmpty) {
      return null;
    }

    return '${RouteNames.serviceDetails}?id=$serviceId';
  }
}
