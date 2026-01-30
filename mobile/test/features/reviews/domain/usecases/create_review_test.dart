import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart';
import 'package:wedy/features/reviews/domain/repositories/review_repository.dart';
import 'package:wedy/features/reviews/domain/usecases/create_review.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late CreateReview useCase;
  late MockReviewRepository mockRepository;

  const tReviewUser = ReviewUser(id: 'user1', name: 'Test User');
  final tReview = Review(
    id: 'review1',
    serviceId: 'service1',
    userId: 'user1',
    merchantId: 'merchant1',
    rating: 5,
    comment: 'Great service!',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    user: tReviewUser,
  );

  setUp(() {
    mockRepository = MockReviewRepository();
    useCase = CreateReview(mockRepository);
  });

  test('should create a review successfully', () async {
    // Arrange
    when(
      () => mockRepository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!'),
    ).thenAnswer((_) async => Right(tReview));

    // Act
    final result = await useCase(serviceId: 'service1', rating: 5, comment: 'Great service!');

    // Assert
    expect(result, Right(tReview));
    verify(() => mockRepository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when serviceId is empty', () async {
    // Act
    final result = await useCase(serviceId: '', rating: 5, comment: 'Great service!');

    // Assert
    expect(result, const Left(ValidationFailure('Service ID cannot be empty')));
    verifyNever(
      () => mockRepository.createReview(
        serviceId: any(named: 'serviceId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  test('should return ValidationFailure when rating is less than 1', () async {
    // Act
    final result = await useCase(serviceId: 'service1', rating: 0, comment: 'Great service!');

    // Assert
    expect(result, const Left(ValidationFailure('Rating must be between 1 and 5')));
    verifyNever(
      () => mockRepository.createReview(
        serviceId: any(named: 'serviceId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  test('should return ValidationFailure when rating is greater than 5', () async {
    // Act
    final result = await useCase(serviceId: 'service1', rating: 6, comment: 'Great service!');

    // Assert
    expect(result, const Left(ValidationFailure('Rating must be between 1 and 5')));
    verifyNever(
      () => mockRepository.createReview(
        serviceId: any(named: 'serviceId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  test('should create review without comment', () async {
    // Arrange
    when(
      () => mockRepository.createReview(serviceId: 'service1', rating: 5, comment: null),
    ).thenAnswer((_) async => Right(tReview));

    // Act
    final result = await useCase(serviceId: 'service1', rating: 5);

    // Assert
    expect(result, Right(tReview));
    verify(() => mockRepository.createReview(serviceId: 'service1', rating: 5, comment: null)).called(1);
  });

  test('should return failure when repository returns failure', () async {
    // Arrange
    when(
      () => mockRepository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!'),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(serviceId: 'service1', rating: 5, comment: 'Great service!');

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!')).called(1);
  });
}
