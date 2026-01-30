import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/reviews/domain/repositories/review_repository.dart';
import 'package:wedy/features/reviews/domain/usecases/delete_review.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late DeleteReview useCase;
  late MockReviewRepository mockRepository;

  setUp(() {
    mockRepository = MockReviewRepository();
    useCase = DeleteReview(mockRepository);
  });

  test('should delete a review successfully', () async {
    // Arrange
    when(() => mockRepository.deleteReview('review1')).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase('review1');

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteReview('review1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when reviewId is empty', () async {
    // Act
    final result = await useCase('');

    // Assert
    expect(result, const Left(ValidationFailure('Review ID cannot be empty')));
    verifyNever(() => mockRepository.deleteReview(any()));
  });

  test('should return failure when repository returns failure', () async {
    // Arrange
    when(
      () => mockRepository.deleteReview('review1'),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase('review1');

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.deleteReview('review1')).called(1);
  });
}
