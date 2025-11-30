import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:wedy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:wedy/features/auth/data/models/auth_dto.dart';
import 'package:wedy/features/auth/data/models/user_model.dart';
import 'package:wedy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wedy/features/auth/domain/entities/auth_tokens.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(SendOtpRequestDto(phoneNumber: ''));
    registerFallbackValue(VerifyOtpRequestDto(phoneNumber: '', otpCode: ''));
    registerFallbackValue(CompleteRegistrationRequestDto(phoneNumber: '', name: '', userType: 'client'));
    registerFallbackValue(RefreshTokenRequestDto(refreshToken: ''));
    registerFallbackValue(const AuthTokens(accessToken: '', refreshToken: ''));
    registerFallbackValue(User(id: '', phoneNumber: '', name: '', type: UserType.client, createdAt: DateTime.now()));
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource, localDataSource: mockLocalDataSource);
  });

  const tPhoneNumber = '901234567';
  const tOtpCode = '123456';
  const tName = 'John Doe';
  final tUserModel = UserModel(
    id: '1',
    phoneNumber: tPhoneNumber,
    name: tName,
    type: UserType.client,
    createdAt: DateTime.now(),
  );

  group('sendOtp', () {
    test('should return Right(null) when OTP is sent successfully', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.sendOtp(any()),
      ).thenAnswer((_) async => SendOtpResponseDto(message: 'OTP sent', phoneNumber: tPhoneNumber, expiresIn: 5));

      // Act
      final result = await repository.sendOtp(tPhoneNumber);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.sendOtp(any())).called(1);
    });

    test('should return ValidationFailure when API returns 400', () async {
      // Arrange
      when(() => mockRemoteDataSource.sendOtp(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {
              'error': {'message': 'Invalid phone number', 'type': 'ValidationError'},
            },
          ),
        ),
      );

      // Act
      final result = await repository.sendOtp(tPhoneNumber);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('should return NetworkFailure on connection timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.sendOtp(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.sendOtp(tPhoneNumber);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, isA<NetworkFailure>());
    });
  });

  group('verifyOtp', () {
    test('should return AuthTokens when OTP is verified for existing user', () async {
      // Arrange
      when(() => mockRemoteDataSource.verifyOtp(any())).thenAnswer(
        (_) async => VerifyOtpResponseDto(
          isNewUser: false,
          accessToken: 'access_token',
          refreshToken: 'refresh_token',
          expiresIn: 15,
          message: 'Success',
        ),
      );
      when(() => mockLocalDataSource.saveTokens(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.verifyOtp(phoneNumber: tPhoneNumber, otpCode: tOtpCode);

      // Assert
      expect(result, isA<Right<Failure, AuthTokens>>());
      final tokens = (result as Right).value;
      expect(tokens.accessToken, 'access_token');
      expect(tokens.refreshToken, 'refresh_token');
      verify(() => mockLocalDataSource.saveTokens(any())).called(1);
    });

    test('should return empty tokens when user is new', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyOtp(any()),
      ).thenAnswer((_) async => VerifyOtpResponseDto(isNewUser: true, message: 'Registration required'));

      // Act
      final result = await repository.verifyOtp(phoneNumber: tPhoneNumber, otpCode: tOtpCode);

      // Assert
      expect(result, isA<Right<Failure, AuthTokens>>());
      final tokens = (result as Right).value;
      expect(tokens.accessToken, '');
      expect(tokens.refreshToken, '');
    });

    test('should return AuthFailure when OTP is invalid', () async {
      // Arrange
      when(() => mockRemoteDataSource.verifyOtp(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {
              'error': {'message': 'Invalid OTP', 'type': 'AuthenticationError'},
            },
          ),
        ),
      );

      // Act
      final result = await repository.verifyOtp(phoneNumber: tPhoneNumber, otpCode: tOtpCode);

      // Assert
      expect(result, isA<Left<Failure, AuthTokens>>());
      expect((result as Left).value, isA<AuthFailure>());
    });
  });

  group('completeRegistration', () {
    test('should return User when registration is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.completeRegistration(any())).thenAnswer(
        (_) async => TokenResponseDto(accessToken: 'access_token', refreshToken: 'refresh_token', expiresIn: 15),
      );
      when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.saveTokens(any())).thenAnswer((_) async => {});
      when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.completeRegistration(
        phoneNumber: tPhoneNumber,
        name: tName,
        userType: UserType.client,
      );

      // Assert
      expect(result, isA<Right<Failure, User>>());
      final user = (result as Right).value;
      expect(user.phoneNumber, tPhoneNumber);
      expect(user.name, tName);
      verify(() => mockLocalDataSource.saveTokens(any())).called(1);
      verify(() => mockLocalDataSource.saveUser(any())).called(1);
    });

    test('should return ValidationFailure when registration fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.completeRegistration(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {
              'error': {'message': 'Name is required', 'type': 'ValidationError'},
            },
          ),
        ),
      );

      // Act
      final result = await repository.completeRegistration(
        phoneNumber: tPhoneNumber,
        name: tName,
        userType: UserType.client,
      );

      // Assert
      expect(result, isA<Left<Failure, User>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });
  });

  group('refreshToken', () {
    test('should return new AuthTokens when refresh is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.refreshToken(any())).thenAnswer(
        (_) async =>
            TokenResponseDto(accessToken: 'new_access_token', refreshToken: 'new_refresh_token', expiresIn: 15),
      );
      when(() => mockLocalDataSource.saveTokens(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.refreshToken('refresh_token');

      // Assert
      expect(result, isA<Right<Failure, AuthTokens>>());
      final tokens = (result as Right).value;
      expect(tokens.accessToken, 'new_access_token');
      expect(tokens.refreshToken, 'new_refresh_token');
      verify(() => mockLocalDataSource.saveTokens(any())).called(1);
    });

    test('should return AuthFailure when refresh token is invalid', () async {
      // Arrange
      when(() => mockRemoteDataSource.refreshToken(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {
              'error': {'message': 'Invalid refresh token', 'type': 'AuthenticationError'},
            },
          ),
        ),
      );

      // Act
      final result = await repository.refreshToken('invalid_token');

      // Assert
      expect(result, isA<Left<Failure, AuthTokens>>());
      expect((result as Left).value, isA<AuthFailure>());
    });
  });
}
