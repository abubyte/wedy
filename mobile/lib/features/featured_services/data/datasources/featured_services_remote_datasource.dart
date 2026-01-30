import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../tariff/data/models/tariff_dto.dart';
import '../models/featured_service_dto.dart';

part 'featured_services_remote_datasource.g.dart';

/// Remote data source for featured services API calls
@RestApi()
abstract class FeaturedServicesRemoteDataSource {
  factory FeaturedServicesRemoteDataSource(Dio dio, {String baseUrl}) = _FeaturedServicesRemoteDataSource;

  /// Get merchant featured services tracking
  @GET('/api/v1/merchants/featured-services')
  Future<MerchantFeaturedServicesDto> getFeaturedServicesTracking();

  /// Create monthly featured service (uses free allocation)
  @POST('/api/v1/merchants/featured-services/monthly')
  Future<FeaturedServiceDto> createMonthlyFeaturedService(@Body() Map<String, dynamic> body);

  /// Create paid featured service payment
  @POST('/api/v1/payments/featured-service')
  Future<PaymentResponseDto> createFeaturedServicePayment(@Body() Map<String, dynamic> body);
}

/// Factory function to create FeaturedServicesRemoteDataSource instance
FeaturedServicesRemoteDataSource createFeaturedServicesRemoteDataSource() {
  return FeaturedServicesRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
}
