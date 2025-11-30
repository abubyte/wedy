import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/profile/domain/repositories/profile_repository.dart';
import 'package:wedy/features/profile/domain/usecases/get_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late GetProfile useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = GetProfile(mockRepository);
  });

  final tUser = User(
    id: '1',
    phoneNumber: '901234567',
    name: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    type: UserType.client,
    createdAt: DateTime.now(),
  );

  test('should get profile successfully', () async {
    // Arrange
    when(() => mockRepository.getProfile()).thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase();

    // Assert
    expect(result, Right(tUser));
    verify(() => mockRepository.getProfile()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(() => mockRepository.getProfile()).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.getProfile()).called(1);
  });

  test('should return AuthFailure when user is not authenticated', () async {
    // Arrange
    when(() => mockRepository.getProfile()).thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(AuthFailure('Unauthorized')));
    verify(() => mockRepository.getProfile()).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    when(() => mockRepository.getProfile()).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.getProfile()).called(1);
  });
}
