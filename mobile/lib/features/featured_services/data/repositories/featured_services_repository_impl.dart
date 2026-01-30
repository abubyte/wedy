import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../tariff/domain/repositories/tariff_repository.dart';
import '../../domain/entities/featured_service.dart';
import '../../domain/repositories/featured_services_repository.dart';
import '../datasources/featured_services_remote_datasource.dart';

/// Featured services repository implementation (data layer)
class FeaturedServicesRepositoryImpl implements FeaturedServicesRepository {
  final FeaturedServicesRemoteDataSource remoteDataSource;

  FeaturedServicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, MerchantFeaturedServicesInfo>> getFeaturedServicesTracking() async {
    try {
      final response = await remoteDataSource.getFeaturedServicesTracking();
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FeaturedService>> createMonthlyFeaturedService(String serviceId) async {
    try {
      final response = await remoteDataSource.createMonthlyFeaturedService({'service_id': serviceId});
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResponse>> createFeaturedServicePayment({
    required String serviceId,
    required int durationDays,
    required String paymentMethod,
  }) async {
    try {
      final body = {'service_id': serviceId, 'duration_days': durationDays, 'payment_method': paymentMethod};
      final response = await remoteDataSource.createFeaturedServicePayment(body);
      return Right(
        PaymentResponse(
          id: response.id,
          amount: response.amount,
          paymentUrl: response.paymentUrl,
          transactionId: response.transactionId,
          createdAt: DateTime.parse(response.createdAt),
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['detail']?.toString() ?? error.message ?? '';
        if (statusCode == 401) {
          return AuthFailure(message.isNotEmpty ? message : 'Unauthorized');
        } else if (statusCode == 402) {
          return ValidationFailure(message.isNotEmpty ? message : 'No free slots available');
        } else if (statusCode == 404) {
          return NotFoundFailure(message.isNotEmpty ? message : 'Service not found');
        } else if (statusCode == 400 || statusCode == 422) {
          return ValidationFailure(message.isNotEmpty ? message : 'Invalid request');
        }
        return ServerFailure(message.isNotEmpty ? message : 'Server error');
      case DioExceptionType.cancel:
        return const NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');
      default:
        return ServerFailure(error.message ?? 'Unknown error');
    }
  }
}
