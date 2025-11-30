import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Local data source for storing auth data securely
class AuthLocalDataSource {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _isLoggedInKey = 'is_logged_in';

  /// Save authentication tokens
  Future<void> saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _storage.write(key: _isLoggedInKey, value: 'true'),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get authentication tokens
  Future<AuthTokens?> getTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    // Calculate expiration (assuming 15 minutes from now)
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt);
  }

  /// Save user data
  Future<void> saveUser(User user) async {
    final userModel = UserModel.fromEntity(user);
    // For now, store as JSON string (can be improved with Hive later)
    await _storage.write(key: _userKey, value: userModel.toJson().toString());
  }

  /// Get cached user data
  Future<User?> getUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData == null) return null;

    // Parse user data (simplified - should use proper JSON parsing)
    // For now, return null and fetch from API
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final isLoggedIn = await _storage.read(key: _isLoggedInKey);
    return isLoggedIn == 'true';
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _isLoggedInKey),
    ]);
  }
}
