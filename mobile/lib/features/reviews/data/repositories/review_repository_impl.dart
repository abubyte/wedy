import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';
import '../models/review_dto.dart';

/// Review repository implementation (data layer)
class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PaginatedReviewResponse>> getServiceReviews({
    required String serviceId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await remoteDataSource.getServiceReviews(serviceId, page: page, limit: limit);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> createReview({
    required String serviceId,
    required int rating,
    String? comment,
  }) async {
    try {
      final request = ReviewCreateRequestDto(serviceId: serviceId, rating: rating, comment: comment);
      final response = await remoteDataSource.createReview(request);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final request = ReviewUpdateRequestDto(rating: rating, comment: comment);
      final response = await remoteDataSource.updateReview(reviewId, request);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    try {
      await remoteDataSource.deleteReview(reviewId);
      return const Right(null);
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
          return const NotFoundFailure('Review not found.');
        } else if (statusCode == 400) {
          return ValidationFailure(error.response?.data['detail'] ?? 'Invalid request.');
        } else if (statusCode == 409) {
          return ValidationFailure(error.response?.data['detail'] ?? 'You have already reviewed this service.');
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

