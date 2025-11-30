import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/profile/domain/repositories/profile_repository.dart';
import 'package:wedy/features/profile/domain/usecases/upload_avatar.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late UploadAvatar useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UploadAvatar(mockRepository);
  });

  const tImagePath = '/path/to/image.jpg';
  const tAvatarUrl = 'https://example.com/avatar.jpg';

  test('should upload avatar successfully', () async {
    // Arrange
    when(() => mockRepository.uploadAvatar(tImagePath)).thenAnswer((_) async => const Right(tAvatarUrl));

    // Act
    final result = await useCase(tImagePath);

    // Assert
    expect(result, const Right(tAvatarUrl));
    verify(() => mockRepository.uploadAvatar(tImagePath)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when image path is empty', () async {
    // Act
    final result = await useCase('');

    // Assert
    expect(result, const Left(ValidationFailure('Image path cannot be empty')));
    verifyNever(() => mockRepository.uploadAvatar(any()));
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.uploadAvatar(tImagePath),
    ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(tImagePath);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.uploadAvatar(tImagePath)).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    when(
      () => mockRepository.uploadAvatar(tImagePath),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(tImagePath);

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.uploadAvatar(tImagePath)).called(1);
  });

  test('should return ValidationFailure when file format is invalid', () async {
    // Arrange
    when(
      () => mockRepository.uploadAvatar(tImagePath),
    ).thenAnswer((_) async => const Left(ValidationFailure('Invalid file format')));

    // Act
    final result = await useCase(tImagePath);

    // Assert
    expect(result, const Left(ValidationFailure('Invalid file format')));
    verify(() => mockRepository.uploadAvatar(tImagePath)).called(1);
  });
}
