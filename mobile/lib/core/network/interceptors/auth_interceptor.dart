import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_client.dart';
import '../../constants/api_constants.dart';

/// Auth interceptor to add JWT token to requests
class AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip adding token for auth endpoints
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Get access token from secure storage
    final accessToken = await _storage.read(key: _accessTokenKey);

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (refreshToken != null) {
        try {
          // Attempt to refresh token using API client (without auth interceptor to avoid recursion)
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            ),
          );

          final response = await refreshDio.post('/api/v1/auth/refresh', data: {'refresh_token': refreshToken});

          if (response.statusCode == 200) {
            final data = response.data;
            final newAccessToken = data['access_token'] as String;
            final newRefreshToken = data['refresh_token'] as String;

            // Save new tokens
            await _storage.write(key: _accessTokenKey, value: newAccessToken);
            await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

            // Retry original request with new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';

            final cloneReq = await ApiClient.instance.request(
              opts.path,
              options: Options(method: opts.method, headers: opts.headers),
              data: opts.data,
              queryParameters: opts.queryParameters,
            );

            return handler.resolve(cloneReq);
          }
        } catch (e) {
          // Refresh failed - clear tokens and let error propagate
          await _storage.delete(key: _accessTokenKey);
          await _storage.delete(key: _refreshTokenKey);
        }
      }
    }

    handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/');
  }

  /// Save tokens to secure storage
  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Clear tokens from secure storage
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Get current access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get current refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
}
