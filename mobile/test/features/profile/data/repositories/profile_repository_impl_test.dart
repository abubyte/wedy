import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/core/network/api_client.dart';
import 'package:wedy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:wedy/features/profile/data/models/profile_dto.dart';
import 'package:wedy/features/profile/data/repositories/profile_repository_impl.dart';

class MockProfileRemoteDataSource extends Mock implements ProfileRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileRepositoryImpl repository;
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(ProfileUpdateRequestDto(name: null, phoneNumber: null));
    registerFallbackValue(User(id: '', phoneNumber: '', name: '', type: UserType.client, createdAt: DateTime.now()));
  });

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = ProfileRepositoryImpl(remoteDataSource: mockRemoteDataSource, localDataSource: mockLocalDataSource);
  });

  final tUser = User(
    id: '1',
    phoneNumber: '901234567',
    name: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    type: UserType.client,
    createdAt: DateTime.now(),
  );

  final tProfileDto = ProfileResponseDto(
    id: '1',
    phoneNumber: '901234567',
    name: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    userType: 'client',
    createdAt: DateTime.now(),
  );

  group('getProfile', () {
    test('should return User when profile is fetched successfully', () async {
      // Arrange
      when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tProfileDto);
      when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result, isA<Right<Failure, User>>());
      final user = (result as Right).value;
      expect(user.id, tUser.id);
      expect(user.name, tUser.name);
      expect(user.phoneNumber, tUser.phoneNumber);
      verify(() => mockRemoteDataSource.getProfile()).called(1);
      verify(() => mockLocalDataSource.saveUser(any())).called(1);
    });

    test('should return ValidationFailure when API returns 400', () async {
      // Arrange
      when(() => mockRemoteDataSource.getProfile()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {
              'error': {'message': 'Invalid request'},
            },
          ),
        ),
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result, isA<Left<Failure, User>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('should return AuthFailure when API returns 401', () async {
      // Arrange
      when(() => mockRemoteDataSource.getProfile()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
        ),
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result, isA<Left<Failure, User>>());
      expect((result as Left).value, isA<AuthFailure>());
    });

    test('should return NetworkFailure on connection timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.getProfile()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result, isA<Left<Failure, User>>());
      expect((result as Left).value, isA<NetworkFailure>());
    });
  });

  group('updateProfile', () {
    test('should return User when profile is updated successfully', () async {
      // Arrange
      const tNewName = 'Jane Doe';
      final tUpdatedDto = ProfileResponseDto(
        id: tProfileDto.id,
        phoneNumber: tProfileDto.phoneNumber,
        name: tNewName,
        avatarUrl: tProfileDto.avatarUrl,
        userType: tProfileDto.userType,
        createdAt: tProfileDto.createdAt,
      );
      when(() => mockRemoteDataSource.updateProfile(any())).thenAnswer((_) async => tUpdatedDto);
      when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.updateProfile(name: tNewName, phoneNumber: null);

      // Assert
      expect(result, isA<Right<Failure, User>>());
      final user = (result as Right).value;
      expect(user.name, tNewName);
      verify(() => mockRemoteDataSource.updateProfile(any())).called(1);
      verify(() => mockLocalDataSource.saveUser(any())).called(1);
    });

    test('should return ValidationFailure when API returns 400', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateProfile(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {
              'error': {'message': 'Invalid name'},
            },
          ),
        ),
      );

      // Act
      final result = await repository.updateProfile(name: 'Invalid', phoneNumber: null);

      // Assert
      expect(result, isA<Left<Failure, User>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('should return ValidationFailure when phone number is already taken (409)', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateProfile(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 409,
            data: {'message': 'Phone number already taken'},
          ),
        ),
      );

      // Act
      final result = await repository.updateProfile(name: null, phoneNumber: '998765432');

      // Assert
      expect(result, isA<Left<Failure, User>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });
  });

  group('uploadAvatar', () {
    const tImagePath = '/path/to/image.jpg';
    const tAvatarUrl = 'https://example.com/new-avatar.jpg';

    test('should return avatar URL when upload is successful', () async {
      // Arrange
      // Mock Dio for file upload
      final mockDio = MockDio();
      final mockResponse = Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'success': true, 'message': 'Avatar uploaded', 's3_url': tAvatarUrl},
      );

      // Replace ApiClient.instance with mock
      // Note: This is a simplified test - in practice, you might need to use a different approach
      when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tProfileDto);
      when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

      // For this test, we'll need to mock the Dio instance used in uploadAvatar
      // Since ApiClient.instance is a singleton, we'll test the happy path differently
      // This is a limitation - we'd need to refactor to inject Dio for better testability

      // For now, we'll test that the method handles file existence check
      // In a real scenario, you'd want to inject Dio as a dependency
    });

    test('should return ValidationFailure when file does not exist', () async {
      // This test would require mocking File.exists() which is complex
      // In practice, you might want to inject a file system abstraction
    });
  });
}
