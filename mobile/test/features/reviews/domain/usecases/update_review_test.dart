import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart';
import 'package:wedy/features/reviews/domain/repositories/review_repository.dart';
import 'package:wedy/features/reviews/domain/usecases/update_review.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late UpdateReview useCase;
  late MockReviewRepository mockRepository;

  final tReview = Review(
    id: 'review1',
    serviceId: 'service1',
    userId: 'user1',
    merchantId: 'merchant1',
    rating: 4,
    comment: 'Updated comment',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockReviewRepository();
    useCase = UpdateReview(mockRepository);
  });

  test('should update a review successfully', () async {
    // Arrange
    when(() => mockRepository.updateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment'))
        .thenAnswer((_) async => Right(tReview));

    // Act
    final result = await useCase(reviewId: 'review1', rating: 4, comment: 'Updated comment');

    // Assert
    expect(result, Right(tReview));
    verify(() => mockRepository.updateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when reviewId is empty', () async {
    // Act
    final result = await useCase(reviewId: '', rating: 4, comment: 'Updated comment');

    // Assert
    expect(result, const Left(ValidationFailure('Review ID cannot be empty')));
    verifyNever(() => mockRepository.updateReview(reviewId: any(named: 'reviewId'), rating: any(named: 'rating'), comment: any(named: 'comment')));
  });

  test('should return ValidationFailure when rating is less than 1', () async {
    // Act
    final result = await useCase(reviewId: 'review1', rating: 0);

    // Assert
    expect(result, const Left(ValidationFailure('Rating must be between 1 and 5')));
    verifyNever(() => mockRepository.updateReview(reviewId: any(named: 'reviewId'), rating: any(named: 'rating'), comment: any(named: 'comment')));
  });

  test('should return ValidationFailure when rating is greater than 5', () async {
    // Act
    final result = await useCase(reviewId: 'review1', rating: 6);

    // Assert
    expect(result, const Left(ValidationFailure('Rating must be between 1 and 5')));
    verifyNever(() => mockRepository.updateReview(reviewId: any(named: 'reviewId'), rating: any(named: 'rating'), comment: any(named: 'comment')));
  });

  test('should update review with only rating', () async {
    // Arrange
    when(() => mockRepository.updateReview(reviewId: 'review1', rating: 4, comment: null))
        .thenAnswer((_) async => Right(tReview));

    // Act
    final result = await useCase(reviewId: 'review1', rating: 4);

    // Assert
    expect(result, Right(tReview));
    verify(() => mockRepository.updateReview(reviewId: 'review1', rating: 4, comment: null)).called(1);
  });

  test('should update review with only comment', () async {
    // Arrange
    when(() => mockRepository.updateReview(reviewId: 'review1', rating: null, comment: 'Updated comment'))
        .thenAnswer((_) async => Right(tReview));

    // Act
    final result = await useCase(reviewId: 'review1', comment: 'Updated comment');

    // Assert
    expect(result, Right(tReview));
    verify(() => mockRepository.updateReview(reviewId: 'review1', rating: null, comment: 'Updated comment')).called(1);
  });

  test('should return failure when repository returns failure', () async {
    // Arrange
    when(() => mockRepository.updateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment'))
        .thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(reviewId: 'review1', rating: 4, comment: 'Updated comment');

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.updateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment')).called(1);
  });
}

