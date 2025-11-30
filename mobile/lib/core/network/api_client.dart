import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Main API client using Dio
class ApiClient {
  static Dio? _instance;

  /// Get singleton Dio instance
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  /// Create and configure Dio instance
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // Add interceptors
    dio.interceptors.addAll([LoggingInterceptor(), AuthInterceptor(), ErrorInterceptor()]);

    return dio;
  }

  /// Reset instance (useful for testing or logout)
  static void reset() {
    _instance = null;
  }
}
