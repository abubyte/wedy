class AppConstants {
  static const String appName = 'Wedy';
  static const String clientAppName = 'Wedy - Find Wedding Services';
  static const String merchantAppName = 'Wedy Business - Manage Your Services';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Validation
  static const int phoneNumberLength = 9;
  static const int otpLength = 6;
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
