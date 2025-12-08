import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';
import 'package:wedy/features/service/domain/usecases/interact_with_service.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late InteractWithService useCase;
  late MockServiceRepository mockRepository;

  setUp(() {
    mockRepository = MockServiceRepository();
    useCase = InteractWithService(mockRepository);
  });

  final tInteractionResponse = ServiceInteractionResponse(
    success: true,
    message: 'Service liked successfully',
    newCount: 51,
  );

  test('should interact with service successfully (like)', () async {
    // Arrange
    const tServiceId = 'service1';
    const tInteractionType = 'like';
    when(
      () => mockRepository.interactWithService(tServiceId, tInteractionType),
    ).thenAnswer((_) async => Right(tInteractionResponse));

    // Act
    final result = await useCase(tServiceId, tInteractionType);

    // Assert
    expect(result, Right(tInteractionResponse));
    verify(() => mockRepository.interactWithService(tServiceId, tInteractionType)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should interact with service successfully (save)', () async {
    // Arrange
    const tServiceId = 'service1';
    const tInteractionType = 'save';
    final tSaveResponse = ServiceInteractionResponse(
      success: true,
      message: 'Service saved successfully',
      newCount: 26,
    );
    when(
      () => mockRepository.interactWithService(tServiceId, tInteractionType),
    ).thenAnswer((_) async => Right(tSaveResponse));

    // Act
    final result = await useCase(tServiceId, tInteractionType);

    // Assert
    expect(result, Right(tSaveResponse));
    verify(() => mockRepository.interactWithService(tServiceId, tInteractionType)).called(1);
  });

  test('should interact with service successfully (share)', () async {
    // Arrange
    const tServiceId = 'service1';
    const tInteractionType = 'share';
    final tShareResponse = ServiceInteractionResponse(
      success: true,
      message: 'Service shared successfully',
      newCount: 11,
    );
    when(
      () => mockRepository.interactWithService(tServiceId, tInteractionType),
    ).thenAnswer((_) async => Right(tShareResponse));

    // Act
    final result = await useCase(tServiceId, tInteractionType);

    // Assert
    expect(result, Right(tShareResponse));
    verify(() => mockRepository.interactWithService(tServiceId, tInteractionType)).called(1);
  });

  test('should return ValidationFailure when service id is empty', () async {
    // Act
    final result = await useCase('', 'like');

    // Assert
    expect(result, const Left(ValidationFailure('Service ID cannot be empty')));
    verifyNever(() => mockRepository.interactWithService(any(), any()));
  });

  test('should return ValidationFailure when interaction type is empty', () async {
    // Act
    final result = await useCase('service1', '');

    // Assert
    expect(result, const Left(ValidationFailure('Interaction type cannot be empty')));
    verifyNever(() => mockRepository.interactWithService(any(), any()));
  });

  test('should return ValidationFailure when interaction type is invalid', () async {
    // Act
    final result = await useCase('service1', 'invalid');

    // Assert
    expect(result, const Left(ValidationFailure('Invalid interaction type. Must be: like, save, share')));
    verifyNever(() => mockRepository.interactWithService(any(), any()));
  });

  test('should normalize interaction type to lowercase', () async {
    // Arrange
    const tServiceId = 'service1';
    const tInteractionType = 'LIKE'; // Uppercase
    when(
      () => mockRepository.interactWithService(tServiceId, 'like'),
    ).thenAnswer((_) async => Right(tInteractionResponse));

    // Act
    final result = await useCase(tServiceId, tInteractionType);

    // Assert
    expect(result, Right(tInteractionResponse));
    verify(() => mockRepository.interactWithService(tServiceId, 'like')).called(1);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    const tServiceId = 'service1';
    const tInteractionType = 'like';
    when(
      () => mockRepository.interactWithService(tServiceId, tInteractionType),
    ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(tServiceId, tInteractionType);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.interactWithService(tServiceId, tInteractionType)).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    const tServiceId = 'service1';
    const tInteractionType = 'like';
    when(
      () => mockRepository.interactWithService(tServiceId, tInteractionType),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(tServiceId, tInteractionType);

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.interactWithService(tServiceId, tInteractionType)).called(1);
  });
}
