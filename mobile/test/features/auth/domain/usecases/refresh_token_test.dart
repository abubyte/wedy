import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/entities/auth_tokens.dart';
import 'package:wedy/features/auth/domain/repositories/auth_repository.dart';
import 'package:wedy/features/auth/domain/usecases/refresh_token.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RefreshToken useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RefreshToken(mockRepository);
  });

  const tRefreshToken = 'refresh_token_string';
  final tAuthTokens = AuthTokens(
    accessToken: 'new_access_token',
    refreshToken: 'new_refresh_token',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
  );

  test('should refresh token successfully', () async {
    // Arrange
    when(() => mockRepository.refreshToken(any())).thenAnswer((_) async => Right(tAuthTokens));

    // Act
    final result = await useCase(tRefreshToken);

    // Assert
    expect(result, Right(tAuthTokens));
    verify(() => mockRepository.refreshToken(tRefreshToken)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when refresh token is empty', () async {
    // Act
    final result = await useCase('');

    // Assert
    expect(result, const Left(ValidationFailure('Refresh token cannot be empty')));
    verifyNever(() => mockRepository.refreshToken(any()));
  });

  test('should return AuthFailure when repository returns authentication error', () async {
    // Arrange
    when(
      () => mockRepository.refreshToken(any()),
    ).thenAnswer((_) async => const Left(AuthFailure('Invalid refresh token')));

    // Act
    final result = await useCase(tRefreshToken);

    // Assert
    expect(result, const Left(AuthFailure('Invalid refresh token')));
    verify(() => mockRepository.refreshToken(tRefreshToken)).called(1);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(() => mockRepository.refreshToken(any())).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(tRefreshToken);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.refreshToken(tRefreshToken)).called(1);
  });
}
