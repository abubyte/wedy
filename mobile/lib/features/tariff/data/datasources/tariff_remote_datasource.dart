import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/tariff_dto.dart';

part 'tariff_remote_datasource.g.dart';

/// Remote data source for tariff API calls
@RestApi()
abstract class TariffRemoteDataSource {
  factory TariffRemoteDataSource(Dio dio, {String baseUrl}) = _TariffRemoteDataSource;

  /// Get all active tariff plans
  @GET('/api/v1/tariffs/')
  Future<List<TariffPlanDto>> getTariffPlans();

  /// Get merchant subscription
  @GET('/api/v1/merchants/subscription')
  Future<SubscriptionWithLimitsResponseDto> getSubscription();

  /// Create tariff payment
  @POST('/api/v1/payments/tariff')
  Future<PaymentResponseDto> createTariffPayment(@Body() Map<String, dynamic> body);

  /// Activate subscription for existing merchant (free 2-month activation)
  @POST('/api/v1/merchants/activate-subscription')
  Future<SubscriptionWithLimitsResponseDto> activateSubscription();
}

/// Factory function to create TariffRemoteDataSource instance
TariffRemoteDataSource createTariffRemoteDataSource() {
  return TariffRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
}
