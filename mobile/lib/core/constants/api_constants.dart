class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String sendOtp = '$apiVersion/auth/send-otp';
  static const String verifyOtp = '$apiVersion/auth/verify-otp';
  static const String completeRegistration = '$apiVersion/auth/complete-registration';
  static const String refreshToken = '$apiVersion/auth/refresh';

  // User endpoints
  static const String userProfile = '$apiVersion/users/profile';
  static const String uploadAvatar = '$apiVersion/users/avatar';

  // Services endpoints
  static const String services = '$apiVersion/services';
  static const String serviceCategories = '$apiVersion/services/categories';
  static const String featuredServices = '$apiVersion/services/featured';

  // Merchant endpoints
  static const String merchantProfile = '$apiVersion/merchants/profile';
  static const String merchantServices = '$apiVersion/merchants/services';

  // Payment endpoints
  static const String tariffs = '$apiVersion/payments/tariffs';
  static const String createPayment = '$apiVersion/payments/tariff';
}
