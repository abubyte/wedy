import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_dto.dart';
import '../models/user_model.dart';

part 'auth_remote_datasource.g.dart';

/// Remote data source for authentication API calls
@RestApi()
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio, {String baseUrl}) = _AuthRemoteDataSource;

  /// Send OTP to phone number
  @POST('/api/v1/auth/send-otp')
  Future<SendOtpResponseDto> sendOtp(@Body() SendOtpRequestDto request);

  /// Verify OTP code
  @POST('/api/v1/auth/verify-otp')
  Future<VerifyOtpResponseDto> verifyOtp(@Body() VerifyOtpRequestDto request);

  /// Complete user registration
  @POST('/api/v1/auth/complete-registration')
  Future<TokenResponseDto> completeRegistration(@Body() CompleteRegistrationRequestDto request);

  /// Refresh access token
  @POST('/api/v1/auth/refresh')
  Future<TokenResponseDto> refreshToken(@Body() RefreshTokenRequestDto request);

  /// Get current user profile
  @GET('/api/v1/users/profile')
  Future<UserModel> getProfile();
}

/// Factory function to create AuthRemoteDataSource instance
AuthRemoteDataSource createAuthRemoteDataSource() =>
    AuthRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
