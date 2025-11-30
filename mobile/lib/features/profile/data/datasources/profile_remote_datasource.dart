import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_dto.dart';

part 'profile_remote_datasource.g.dart';

/// Remote data source for profile API calls
@RestApi()
abstract class ProfileRemoteDataSource {
  factory ProfileRemoteDataSource(Dio dio, {String baseUrl}) = _ProfileRemoteDataSource;

  /// Get current user profile
  @GET('/api/v1/users/profile')
  Future<ProfileResponseDto> getProfile();

  /// Update user profile
  @PUT('/api/v1/users/profile')
  Future<ProfileResponseDto> updateProfile(@Body() ProfileUpdateRequestDto request);
}

/// Factory function to create ProfileRemoteDataSource instance
ProfileRemoteDataSource createProfileRemoteDataSource() {
  return ProfileRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
}
