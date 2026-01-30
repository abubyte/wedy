import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

/// Category repository implementation (data layer)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CategoriesResponse>> getCategories() async {
    try {
      final response = await remoteDataSource.getCategories();
      return Right(response.toEntity());
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
          return const NotFoundFailure('Categories not found.');
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
