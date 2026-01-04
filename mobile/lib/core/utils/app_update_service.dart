import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for checking and handling app updates
class AppUpdateService {
  static const String _playStorePackageName = 'uz.wedy.app'; // Update with your actual package name
  static const String _appStoreId = '1234567890'; // Update with your actual App Store ID

  /// Check for app updates and show dialog if update is available
  ///
  /// [forceUpdate] - If true, user cannot dismiss the dialog and must update
  /// [minVersion] - Minimum required version (e.g., "1.0.0")
  /// [currentVersion] - Current app version
  static Future<void> checkForUpdate({
    required BuildContext context,
    bool forceUpdate = false,
    String? minVersion,
    String? currentVersion,
  }) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = currentVersion ?? packageInfo.version;

      // Check if update is required based on minVersion
      if (minVersion != null && _isUpdateRequired(localVersion, minVersion)) {
        _showUpdateDialog(context: context, forceUpdate: true, message: 'Yangi versiya mavjud. Iltimos, yangilang.');
        return;
      }

      // For Android, use in-app update
      if (Platform.isAndroid) {
        await _checkAndroidUpdate(context, forceUpdate: forceUpdate);
      } else if (Platform.isIOS) {
        // For iOS, check App Store version (requires backend API)
        await _checkIOSUpdate(context, forceUpdate: forceUpdate);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      // Silently fail - don't interrupt user experience
    }
  }

  /// Check for Android updates using in-app update
  static Future<void> _checkAndroidUpdate(BuildContext context, {bool forceUpdate = false}) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          // Immediate update available (force update)
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Flexible update available (optional)
          if (forceUpdate) {
            _showUpdateDialog(
              context: context,
              forceUpdate: true,
              message: 'Yangi versiya mavjud. Iltimos, yangilang.',
            );
          } else {
            _showUpdateDialog(
              context: context,
              forceUpdate: false,
              message: 'Yangi versiya mavjud. Yangilashni tavsiya qilamiz.',
            );
          }
        } else {
          // Update available but not allowed, show dialog to open Play Store
          _showUpdateDialog(
            context: context,
            forceUpdate: forceUpdate,
            message: forceUpdate
                ? 'Yangi versiya mavjud. Iltimos, yangilang.'
                : 'Yangi versiya mavjud. Yangilashni tavsiya qilamiz.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking Android update: $e');
    }
  }

  /// Check for iOS updates (requires backend API to check App Store version)
  static Future<void> _checkIOSUpdate(BuildContext context, {bool forceUpdate = false}) async {
    // For iOS, we need to check App Store version via backend API
    // or use a service like AppVersionChecker
    // For now, we'll show a dialog that opens App Store
    try {
      // You can implement backend API call here to check latest version
      // For now, we'll just show the update dialog
      _showUpdateDialog(
        context: context,
        forceUpdate: forceUpdate,
        message: forceUpdate
            ? 'Yangi versiya mavjud. Iltimos, yangilang.'
            : 'Yangi versiya mavjud. Yangilashni tavsiya qilamiz.',
      );
    } catch (e) {
      debugPrint('Error checking iOS update: $e');
    }
  }

  /// Show update dialog
  static void _showUpdateDialog({required BuildContext context, required bool forceUpdate, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: AlertDialog(
          title: const Text('Yangilanish'),
          content: Text(message),
          actions: [
            if (!forceUpdate) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keyinroq')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openStore();
              },
              child: const Text('Yangilash'),
            ),
          ],
        ),
      ),
    );
  }

  /// Open Play Store or App Store
  static Future<void> _openStore() async {
    try {
      final Uri url;
      if (Platform.isAndroid) {
        url = Uri.parse('https://play.google.com/store/apps/details?id=$_playStorePackageName');
      } else if (Platform.isIOS) {
        url = Uri.parse('https://apps.apple.com/app/id$_appStoreId');
      } else {
        return;
      }

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening store: $e');
    }
  }

  /// Check if update is required by comparing versions
  static bool _isUpdateRequired(String currentVersion, String minVersion) {
    final current = _parseVersion(currentVersion);
    final minimum = _parseVersion(minVersion);

    if (current[0] < minimum[0]) return true;
    if (current[0] > minimum[0]) return false;

    if (current[1] < minimum[1]) return true;
    if (current[1] > minimum[1]) return false;

    if (current[2] < minimum[2]) return true;

    return false;
  }

  /// Parse version string to [major, minor, patch]
  static List<int> _parseVersion(String version) {
    final parts = version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.sublist(0, 3);
  }

  /// Start flexible update (for Android)
  static Future<void> startFlexibleUpdate() async {
    if (Platform.isAndroid) {
      try {
        await InAppUpdate.startFlexibleUpdate();
      } catch (e) {
        debugPrint('Error starting flexible update: $e');
      }
    }
  }

  /// Complete flexible update (for Android)
  static Future<void> completeFlexibleUpdate() async {
    if (Platform.isAndroid) {
      try {
        await InAppUpdate.completeFlexibleUpdate();
      } catch (e) {
        debugPrint('Error completing flexible update: $e');
      }
    }
  }
}
