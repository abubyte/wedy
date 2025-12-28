import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/tariff.dart';
import '../../domain/repositories/tariff_repository.dart';
import '../datasources/tariff_remote_datasource.dart';

/// Tariff repository implementation (data layer)
class TariffRepositoryImpl implements TariffRepository {
  final TariffRemoteDataSource remoteDataSource;

  TariffRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TariffPlan>>> getTariffPlans() async {
    try {
      final response = await remoteDataSource.getTariffPlans();
      return Right(response.map((dto) => dto.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subscription?>> getSubscription() async {
    try {
      final response = await remoteDataSource.getSubscription();
      // Handle case where subscription is null (no active subscription)
      if (response.subscription == null) {
        return const Right(null);
      }
      return Right(response.subscription!.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No subscription found
        return const Right(null);
      }
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResponse>> createTariffPayment({
    required String tariffPlanId,
    required int durationMonths,
    required String paymentMethod,
  }) async {
    try {
      final body = {'tariff_plan_id': tariffPlanId, 'duration_months': durationMonths, 'payment_method': paymentMethod};
      final response = await remoteDataSource.createTariffPayment(body);
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

  @override
  Future<Either<Failure, Subscription?>> activateSubscription() async {
    try {
      final response = await remoteDataSource.activateSubscription();
      // Handle case where subscription is null (shouldn't happen after activation)
      if (response.subscription == null) {
        return const Right(null);
      }
      return Right(response.subscription!.toEntity());
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
        return const NetworkFailure('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return const AuthFailure('Unauthorized. Please login again.');
        } else if (statusCode == 404) {
          return const NotFoundFailure('Resource not found.');
        } else if (statusCode == 400) {
          return ValidationFailure(error.response?.data['detail'] ?? 'Invalid request.');
        } else if (statusCode != null && statusCode >= 500) {
          return const ServerFailure('Server error. Please try again later.');
        }
        return ServerFailure(error.response?.data['detail'] ?? 'An error occurred.');
      case DioExceptionType.cancel:
        return const NetworkFailure('Request cancelled.');
      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') == true) {
          return const NetworkFailure('No internet connection.');
        }
        return ServerFailure(error.message ?? 'An unexpected error occurred.');
    }
  }
}
