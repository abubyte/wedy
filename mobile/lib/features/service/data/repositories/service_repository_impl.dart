import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';
import '../models/service_dto.dart';

/// Service repository implementation (data layer)
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PaginatedServiceResponse>> getServices({
    bool? featured,
    ServiceSearchFilters? filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await remoteDataSource.getServices(
        featured: featured,
        query: filters?.query,
        categoryId: filters?.categoryId,
        locationRegion: filters?.locationRegion,
        minPrice: filters?.minPrice,
        maxPrice: filters?.maxPrice,
        minRating: filters?.minRating,
        isVerifiedMerchant: filters?.isVerifiedMerchant,
        sortBy: filters?.sortBy,
        sortOrder: filters?.sortOrder,
        page: page,
        limit: limit,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Service>> getServiceById(String serviceId) async {
    try {
      final response = await remoteDataSource.getServiceById(serviceId);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceInteractionResponse>> interactWithService(
    String serviceId,
    String interactionType,
  ) async {
    try {
      final response = await remoteDataSource.interactWithService(serviceId, {'interaction_type': interactionType});
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceListItem>>> getSavedServices() async {
    try {
      final response = await remoteDataSource.getUserInteractions();
      return Right(response.toSavedServicesEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceListItem>>> getLikedServices() async {
    try {
      final response = await remoteDataSource.getUserInteractions();
      return Right(response.toLikedServicesEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MerchantServicesResponse>> getMerchantServices() async {
    try {
      final response = await remoteDataSource.getMerchantServices();
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Service>> createService({
    required String name,
    required String description,
    required int categoryId,
    required double price,
    required String locationRegion,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final requestDto = ServiceCreateRequestDto(
        name: name,
        description: description,
        categoryId: categoryId,
        price: price,
        locationRegion: locationRegion,
        latitude: latitude,
        longitude: longitude,
      );
      final response = await remoteDataSource.createService(requestDto.toJson());
      return Right(response.toServiceEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Service>> updateService({
    required String serviceId,
    String? name,
    String? description,
    int? categoryId,
    double? price,
    String? locationRegion,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final requestDto = ServiceUpdateRequestDto(
        name: name,
        description: description,
        categoryId: categoryId,
        price: price,
        locationRegion: locationRegion,
        latitude: latitude,
        longitude: longitude,
      );
      // Remove null values from the request
      final requestBody = requestDto.toJson();
      requestBody.removeWhere((key, value) => value == null);
      final response = await remoteDataSource.updateService(serviceId, requestBody);
      return Right(response.toServiceEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteService(String serviceId) async {
    try {
      await remoteDataSource.deleteService(serviceId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadServiceImage({
    required String serviceId,
    required File file,
    required String contentType,
    int displayOrder = 0,
  }) async {
    try {
      // Get presigned URL from backend
      final response = await remoteDataSource.getServiceImageUploadUrl(serviceId, file, displayOrder);

      if (response.presignedUrl == null) {
        return const Left(ServerFailure('No presigned URL received'));
      }

      // Upload file to S3 using presigned URL
      if (!await file.exists()) {
        return const Left(ValidationFailure('Image file does not exist'));
      }

      final dio = Dio();
      final fileBytes = await file.readAsBytes();

      await dio.put(
        response.presignedUrl!,
        data: fileBytes,
        options: Options(headers: {'Content-Type': contentType}),
      );

      return Right(response.s3Url ?? '');
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
      case DioExceptionType.connectionError:
        return const NetworkFailure('Connection error. Please check your internet connection and try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return const AuthFailure('Unauthorized. Please login again.');
        } else if (statusCode == 404) {
          return const NotFoundFailure('Service not found.');
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
