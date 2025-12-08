import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart';
import 'package:wedy/features/reviews/domain/repositories/review_repository.dart';
import 'package:wedy/features/reviews/domain/usecases/get_reviews.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late GetReviews useCase;
  late MockReviewRepository mockRepository;

  const tReviewUser = ReviewUser(id: 'user1', name: 'Test User', avatarUrl: 'https://example.com/avatar.jpg');
  const tReviewService = ReviewService(id: 'service1', name: 'Test Service');
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
    service: tReviewService,
  );

  final tPaginatedResponse = PaginatedReviewResponse(
    reviews: [tReview],
    total: 1,
    page: 1,
    limit: 20,
    hasMore: false,
    totalPages: 1,
  );

  setUp(() {
    mockRepository = MockReviewRepository();
    useCase = GetReviews(mockRepository);
  });

  test('should get reviews for a service from the repository', () async {
    // Arrange
    when(() => mockRepository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20))
        .thenAnswer((_) async => Right(tPaginatedResponse));

    // Act
    final result = await useCase(serviceId: 'service1', page: 1, limit: 20);

    // Assert
    expect(result, Right(tPaginatedResponse));
    verify(() => mockRepository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when serviceId is empty', () async {
    // Act
    final result = await useCase(serviceId: '', page: 1, limit: 20);

    // Assert
    expect(result, const Left(ValidationFailure('Service ID cannot be empty')));
    verifyNever(() => mockRepository.getServiceReviews(serviceId: any(named: 'serviceId'), page: any(named: 'page'), limit: any(named: 'limit')));
  });

  test('should return failure when repository returns failure', () async {
    // Arrange
    when(() => mockRepository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20))
        .thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(serviceId: 'service1', page: 1, limit: 20);

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20)).called(1);
  });
}

