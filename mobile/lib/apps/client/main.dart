import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wedy/core/config/app_config.dart';
import 'package:wedy/core/theme/app_colors.dart';

import '../../core/di/injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration
  final environment = _getEnvironment();
  AppConfig.initialize(appType: AppType.client, environment: environment);

  // Initialize dependency injection
  await di.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const WedyClientApp());
}

/// Get environment from build arguments or environment variable
/// Priority: Build arguments > Environment variable > Default (development)
Environment _getEnvironment() {
  // Check for build argument (set via --dart-define)
  const envString = String.fromEnvironment('ENVIRONMENT', defaultValue: '');

  if (envString.isNotEmpty) {
    switch (envString.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
  }

  // Default to development
  return Environment.development;
}
