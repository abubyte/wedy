/// App type enum
enum AppType { client, merchant }

/// Environment enum
enum Environment { development, staging, production }

/// Application configuration class
/// This class holds all environment-specific and app-specific configurations
class AppConfig {
  AppConfig._();

  static AppConfig? _instance;
  static AppConfig get instance {
    if (_instance == null) {
      throw Exception(
        'AppConfig not initialized. Call AppConfig.initialize() first.',
      );
    }
    return _instance!;
  }

  late final AppType appType;
  late final Environment environment;
  late final String baseUrl;
  late final String apiVersion;
  late final String appName;
  late final String packageName;
  late final String bundleId;
  late final bool enableLogging;
  late final bool enableAnalytics;
  late final String googleMapsApiKey;

  /// Initialize the app configuration
  /// This should be called before runApp()
  static void initialize({
    required AppType appType,
    required Environment environment,
  }) {
    _instance = AppConfig._();
    _instance!.appType = appType;
    _instance!.environment = environment;

    // Set environment-specific values
    switch (environment) {
      case Environment.development:
        _instance!.baseUrl = 'http://api.abubyte.uz';
        _instance!.enableLogging = true;
        _instance!.enableAnalytics = false;
        break;
      case Environment.staging:
        _instance!.baseUrl = 'https://staging-api.wedy.uz';
        _instance!.enableLogging = true;
        _instance!.enableAnalytics = true;
        break;
      case Environment.production:
        _instance!.baseUrl = 'https://api.wedy.uz';
        _instance!.enableLogging = false;
        _instance!.enableAnalytics = true;
        break;
    }

    // Set app-specific values
    switch (appType) {
      case AppType.client:
        _instance!.appName = environment == Environment.production
            ? 'Wedy'
            : 'Wedy Client (${environment.name})';
        _instance!.packageName = environment == Environment.production
            ? 'uz.wedy.app'
            : 'uz.wedy.app.${environment.name}';
        _instance!.bundleId = environment == Environment.production
            ? 'uz.wedy.app'
            : 'uz.wedy.app.${environment.name}';
        break;
      case AppType.merchant:
        _instance!.appName = environment == Environment.production
            ? 'Wedy Business'
            : 'Wedy Business (${environment.name})';
        _instance!.packageName = environment == Environment.production
            ? 'uz.wedy.business'
            : 'uz.wedy.business.${environment.name}';
        _instance!.bundleId = environment == Environment.production
            ? 'uz.wedy.business'
            : 'uz.wedy.business.${environment.name}';
        break;
    }

    // Common values
    _instance!.apiVersion = '/api/v1';

    // Google Maps API key (TODO: Move to environment variables or secure storage)
    _instance!.googleMapsApiKey = 'AIzaSyAbOGkhFhfS0xG6E5o3KGX1MvwdxoimDFU';
  }

  /// Get full API URL
  String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Check if current environment is production
  bool get isProduction => environment == Environment.production;

  /// Check if current environment is development
  bool get isDevelopment => environment == Environment.development;

  /// Check if current app is client
  bool get isClient => appType == AppType.client;

  /// Check if current app is merchant
  bool get isMerchant => appType == AppType.merchant;

  @override
  String toString() {
    return 'AppConfig(appType: $appType, environment: $environment, '
        'baseUrl: $baseUrl, packageName: $packageName)';
  }
}
