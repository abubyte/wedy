import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_dto.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Either<Failure, void>> sendOtp(String phoneNumber) async {
    try {
      final request = SendOtpRequestDto(phoneNumber: phoneNumber);
      await remoteDataSource.sendOtp(request);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> verifyOtp({required String phoneNumber, required String otpCode}) async {
    try {
      final request = VerifyOtpRequestDto(phoneNumber: phoneNumber, otpCode: otpCode);
      final response = await remoteDataSource.verifyOtp(request);

      // If user exists, save tokens
      if (!response.isNewUser && response.accessToken != null && response.refreshToken != null) {
        final tokens = AuthTokens(
          accessToken: response.accessToken!,
          refreshToken: response.refreshToken!,
          expiresAt: DateTime.now().add(Duration(minutes: response.expiresIn ?? 15)),
        );

        // Save tokens to secure storage
        try {
          await AuthInterceptor.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
        } catch (e) {
          // Ignore storage errors in tests or if secure storage is unavailable
        }
        await localDataSource.saveTokens(tokens);

        return Right(tokens);
      }

      // New user - return empty tokens to indicate registration needed
      return const Right(AuthTokens(accessToken: '', refreshToken: '', expiresAt: null));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> completeRegistration({
    required String phoneNumber,
    required String name,
    required UserType userType,
  }) async {
    try {
      final request = CompleteRegistrationRequestDto(phoneNumber: phoneNumber, name: name, userType: userType.name);

      final tokenResponse = await remoteDataSource.completeRegistration(request);

      // Save tokens
      final tokens = AuthTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        expiresAt: DateTime.now().add(Duration(minutes: tokenResponse.expiresIn)),
      );

      try {
        await AuthInterceptor.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      } catch (e) {
        // Ignore storage errors in tests or if secure storage is unavailable
      }
      await localDataSource.saveTokens(tokens);

      // Fetch user profile
      final userModel = await remoteDataSource.getProfile();
      await localDataSource.saveUser(userModel.toEntity());

      return Right(userModel.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final request = RefreshTokenRequestDto(refreshToken: refreshToken);
      final response = await remoteDataSource.refreshToken(request);

      final tokens = AuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: DateTime.now().add(Duration(minutes: response.expiresIn)),
      );

      // Save new tokens
      try {
        await AuthInterceptor.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      } catch (e) {
        // Ignore storage errors in tests or if secure storage is unavailable
      }
      await localDataSource.saveTokens(tokens);

      return Right(tokens);
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

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final userModel = await remoteDataSource.getProfile();
      await localDataSource.saveUser(userModel.toEntity());
      return Right(userModel.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
