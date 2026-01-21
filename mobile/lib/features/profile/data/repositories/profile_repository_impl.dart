import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_dto.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

/// Implementation of ProfileRepository
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final profileDto = await remoteDataSource.getProfile();
      final user = profileDto.toEntity();

      // Update local storage
      await localDataSource.saveUser(user);

      return Right(user);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({String? name, String? phoneNumber, String? otpCode}) async {
    try {
      final request = ProfileUpdateRequestDto(name: name, phoneNumber: phoneNumber, otpCode: otpCode);

      final profileDto = await remoteDataSource.updateProfile(request);
      final user = profileDto.toEntity();

      // Update local storage
      await localDataSource.saveUser(user);

      return Right(user);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(String imagePath) async {
    try {
      // Create multipart file from image path
      final file = File(imagePath);
      if (!await file.exists()) {
        return const Left(ValidationFailure('Image file does not exist'));
      }

      final fileName = file.path.split('/').last;

      // Use Dio directly for file upload (Retrofit doesn't handle MultipartFile well)
      final dio = ApiClient.instance;
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(imagePath, filename: fileName)});

      final response = await dio.post(
        '/api/v1/users/avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final avatarResponse = AvatarUploadResponseDto.fromJson(response.data);

      // Update user profile with new avatar URL
      final profileResult = await getProfile();

      return profileResult.fold((failure) => Left(failure), (_) => Right(avatarResponse.s3Url));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    try {
      final dio = ApiClient.instance;
      await dio.delete('/api/v1/users/avatar');

      // Reload profile to get updated user data
      await getProfile();

      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Handle Dio errors and convert to appropriate Failure
  Failure _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final errorData = error.response!.data;

      // Extract error message from response
      String message = 'An error occurred';
      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey('error')) {
          final errorObj = errorData['error'];
          if (errorObj is Map<String, dynamic> && errorObj.containsKey('message')) {
            message = errorObj['message'] as String;
          }
        } else if (errorData.containsKey('message')) {
          message = errorData['message'] as String;
        } else if (errorData.containsKey('detail')) {
          message = errorData['detail'] as String;
        }
      }

      switch (statusCode) {
        case 400:
          return ValidationFailure(message);
        case 401:
          return AuthFailure(message);
        case 403:
          return AuthFailure(message);
        case 404:
          return NotFoundFailure(message);
        case 409:
          return ValidationFailure(message); // Conflict (e.g., phone number taken)
        case 500:
        case 502:
        case 503:
          return ServerFailure(message);
        default:
          return NetworkFailure(message);
      }
    }

    // Network or timeout error
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure('Connection timeout. Please check your internet.');
    }

    if (error.type == DioExceptionType.unknown) {
      return NetworkFailure(error.error?.toString() ?? 'Network error. Please check your connection.');
    }

    return NetworkFailure(error.message ?? 'Network error occurred');
  }
}
