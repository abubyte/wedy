import '../config/app_config.dart';

class ApiConstants {
  // Base URL and API version from AppConfig
  static String get baseUrl => AppConfig.instance.baseUrl;
  static String get apiVersion => AppConfig.instance.apiVersion;
  static String get apiBaseUrl => AppConfig.instance.apiBaseUrl;

  // Auth endpoints
  static String get sendOtp => '$apiVersion/auth/send-otp';
  static String get verifyOtp => '$apiVersion/auth/verify-otp';
  static String get completeRegistration => '$apiVersion/auth/complete-registration';
  static String get refreshToken => '$apiVersion/auth/refresh';

  // User endpoints
  static String get userProfile => '$apiVersion/users/profile';
  static String get uploadAvatar => '$apiVersion/users/avatar';
  static String get userInteractions => '$apiVersion/users/interactions';

  // Services endpoints
  static String get services => '$apiVersion/services';
  static String get featuredServices => '$apiVersion/services/featured';

  // Categories endpoints
  static String get categories => '$apiVersion/categories';

  // Reviews endpoints
  static String get reviews => '$apiVersion/reviews';

  // Merchant endpoints
  static String get merchantProfile => '$apiVersion/merchants/profile';
  static String get merchantServices => '$apiVersion/services/my';

  // Tariff endpoints
  static String get tariffs => '$apiVersion/tariffs/';
  static String get subscription => '$apiVersion/merchants/subscription';

  // Payment endpoints
  static String get createTariffPayment => '$apiVersion/payments/tariff';
}
