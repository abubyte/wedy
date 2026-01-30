import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/gallery_image.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../datasources/gallery_remote_datasource.dart';

/// Gallery repository implementation (data layer)
class GalleryRepositoryImpl implements GalleryRepository {
  final GalleryRemoteDataSource remoteDataSource;

  GalleryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<GalleryImage>>> getGalleryImages() async {
    try {
      final response = await remoteDataSource.getGalleryImages();
      return Right(response.map((dto) => dto.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ImageUploadResult>> addGalleryImage({required File file, required int displayOrder}) async {
    try {
      final response = await remoteDataSource.addGalleryImage(file, displayOrder);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGalleryImage(String imageId) async {
    try {
      await remoteDataSource.deleteGalleryImage(imageId);
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
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['detail']?.toString() ?? error.message ?? '';
        if (statusCode == 401) {
          return AuthFailure(message.isNotEmpty ? message : 'Unauthorized');
        } else if (statusCode == 402) {
          return ValidationFailure(message.isNotEmpty ? message : 'Tariff limit exceeded');
        } else if (statusCode == 404) {
          return NotFoundFailure(message.isNotEmpty ? message : 'Image not found');
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
