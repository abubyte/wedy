import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/service_dto.dart';
import '../models/user_interaction_dto.dart';

part 'service_remote_datasource.g.dart';

/// Remote data source for service API calls
@RestApi()
abstract class ServiceRemoteDataSource {
  factory ServiceRemoteDataSource(Dio dio, {String baseUrl}) = _ServiceRemoteDataSource;

  /// Get paginated list of services with optional filters
  @GET('/api/v1/services/')
  Future<PaginatedServiceResponseDto> getServices({
    @Query('featured') bool? featured,
    @Query('query') String? query,
    @Query('category_id') int? categoryId,
    @Query('location_region') String? locationRegion,
    @Query('min_price') double? minPrice,
    @Query('max_price') double? maxPrice,
    @Query('min_rating') double? minRating,
    @Query('is_verified_merchant') bool? isVerifiedMerchant,
    @Query('sort_by') String? sortBy,
    @Query('sort_order') String? sortOrder,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  /// Get service details by ID
  @GET('/api/v1/services/{serviceId}')
  Future<ServiceDetailDto> getServiceById(@Path('serviceId') String serviceId);

  /// Interact with service (like, save, share)
  @POST('/api/v1/services/{serviceId}/interact')
  Future<ServiceInteractionResponseDto> interactWithService(
    @Path('serviceId') String serviceId,
    @Body() Map<String, dynamic> body,
  );

  /// Get user's saved services
  @GET('/api/v1/users/interactions')
  Future<UserInteractionsResponseDto> getUserInteractions();

  /// Get merchant's services
  @GET('/api/v1/services/my')
  Future<MerchantServicesResponseDto> getMerchantServices();

  /// Create a new service
  @POST('/api/v1/services/')
  Future<ServiceDetailDto> createService(@Body() Map<String, dynamic> body);

  /// Update a service
  @PUT('/api/v1/services/{serviceId}')
  Future<ServiceDetailDto> updateService(@Path('serviceId') String serviceId, @Body() Map<String, dynamic> body);

  /// Delete a service
  @DELETE('/api/v1/services/{serviceId}')
  Future<void> deleteService(@Path('serviceId') String serviceId);
}

/// Factory function to create ServiceRemoteDataSource instance
ServiceRemoteDataSource createServiceRemoteDataSource() {
  return ServiceRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
}
