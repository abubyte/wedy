import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart';
import 'package:wedy/features/reviews/domain/usecases/create_review.dart';
import 'package:wedy/features/reviews/domain/usecases/delete_review.dart';
import 'package:wedy/features/reviews/domain/usecases/get_reviews.dart';
import 'package:wedy/features/reviews/domain/usecases/update_review.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_bloc.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_event.dart';
import 'package:wedy/features/reviews/presentation/bloc/review_state.dart';

class MockGetReviews extends Mock implements GetReviews {}

class MockCreateReview extends Mock implements CreateReview {}

class MockUpdateReview extends Mock implements UpdateReview {}

class MockDeleteReview extends Mock implements DeleteReview {}

void main() {
  late ReviewBloc bloc;
  late MockGetReviews mockGetReviews;
  late MockCreateReview mockCreateReview;
  late MockUpdateReview mockUpdateReview;
  late MockDeleteReview mockDeleteReview;

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

  final tPaginatedResponse = PaginatedReviewResponse(
    reviews: [tReview],
    total: 1,
    page: 1,
    limit: 20,
    hasMore: false,
    totalPages: 1,
  );

  setUp(() {
    mockGetReviews = MockGetReviews();
    mockCreateReview = MockCreateReview();
    mockUpdateReview = MockUpdateReview();
    mockDeleteReview = MockDeleteReview();
    bloc = ReviewBloc(
      getReviewsUseCase: mockGetReviews,
      createReviewUseCase: mockCreateReview,
      updateReviewUseCase: mockUpdateReview,
      deleteReviewUseCase: mockDeleteReview,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('LoadReviewsEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewsLoaded] when reviews are loaded successfully',
      build: () {
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => Right(tPaginatedResponse));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20)),
      expect: () => [
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
      ],
      verify: (_) {
        verify(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20)).called(1);
      },
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewError] when loading fails',
      build: () {
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => const Left(ServerFailure('Server error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20)),
      expect: () => [
        const ReviewLoading(),
        const ReviewError('Server error. Please try again later.'),
      ],
    );
  });

  group('LoadMoreReviewsEvent', () {
    test('LoadMoreReviewsEvent emits [ReviewsLoaded] with more reviews when loading more succeeds', () async {
      // Arrange
      final firstResponse = PaginatedReviewResponse(
        reviews: [tReview],
        total: 2,
        page: 1,
        limit: 20,
        hasMore: true,
        totalPages: 2,
      );
      when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
          .thenAnswer((_) async => Right(firstResponse));
      final secondResponse = PaginatedReviewResponse(
        reviews: [tReview],
        total: 2,
        page: 2,
        limit: 20,
        hasMore: false,
        totalPages: 2,
      );
      when(() => mockGetReviews(serviceId: 'service1', page: 2, limit: 20))
          .thenAnswer((_) async => Right(secondResponse));

      // Act - Load first page
      bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20));
      await bloc.stream.firstWhere((state) => state is ReviewsLoaded);

      // Act - Load more
      bloc.add(const LoadMoreReviewsEvent());
      final states = <ReviewState>[];
      await bloc.stream.take(1).forEach((state) => states.add(state));

      // Assert
      expect(states.length, 1);
      expect(states[0], isA<ReviewsLoaded>());
      final loadedState = states[0] as ReviewsLoaded;
      expect(loadedState.allReviews.length, 2);
      expect(loadedState.response.page, 2);
      expect(loadedState.response.hasMore, false);
    });

    blocTest<ReviewBloc, ReviewState>(
      'does not emit when hasMore is false',
      build: () {
        final noMoreResponse = PaginatedReviewResponse(
          reviews: [tReview],
          total: 1,
          page: 1,
          limit: 20,
          hasMore: false,
          totalPages: 1,
        );
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => Right(noMoreResponse));
        return bloc;
      },
      act: (bloc) {
        // First load reviews to set _hasMore to false
        bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20));
        // Then try to load more - should not emit anything
        bloc.add(const LoadMoreReviewsEvent());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const ReviewLoading(),
        ReviewsLoaded(
          response: PaginatedReviewResponse(
            reviews: [tReview],
            total: 1,
            page: 1,
            limit: 20,
            hasMore: false,
            totalPages: 1,
          ),
          allReviews: [tReview],
        ),
        // Should not emit anything after LoadMoreReviewsEvent since hasMore is false
      ],
    );
  });

  group('CreateReviewEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewCreated, ReviewLoading, ReviewsLoaded] when review is created successfully',
      build: () {
        when(() => mockCreateReview(serviceId: 'service1', rating: 5, comment: 'Great service!'))
            .thenAnswer((_) async => Right(tReview));
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => Right(tPaginatedResponse));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateReviewEvent(serviceId: 'service1', rating: 5, comment: 'Great service!')),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        ReviewCreated(tReview),
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewError] when creation fails',
      build: () {
        when(() => mockCreateReview(serviceId: 'service1', rating: 5, comment: 'Great service!'))
            .thenAnswer((_) async => const Left(ValidationFailure('You have already reviewed this service.')));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateReviewEvent(serviceId: 'service1', rating: 5, comment: 'Great service!')),
      expect: () => [
        const ReviewError('You have already reviewed this service.'),
      ],
    );
  });

  group('UpdateReviewEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewUpdated, ReviewLoading, ReviewsLoaded] when review is updated successfully',
      build: () {
        when(() => mockUpdateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment'))
            .thenAnswer((_) async => Right(tReview));
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => Right(tPaginatedResponse));
        return bloc;
      },
      act: (bloc) {
        // First load reviews to set currentServiceId
        bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20));
        // Then update review
        bloc.add(const UpdateReviewEvent(reviewId: 'review1', rating: 4, comment: 'Updated comment'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
        ReviewUpdated(tReview),
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
      ],
    );
  });

  group('DeleteReviewEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewDeleted, ReviewLoading, ReviewsLoaded] when review is deleted successfully',
      build: () {
        when(() => mockDeleteReview('review1')).thenAnswer((_) async => const Right(null));
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => Right(tPaginatedResponse));
        return bloc;
      },
      seed: () {
        // Seed with initial loaded state
        return ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]);
      },
      act: (bloc) {
        // First load reviews to set currentServiceId
        bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20));
        // Then delete
        bloc.add(const DeleteReviewEvent('review1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
        const ReviewDeleted(),
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
      ],
    );
  });

  group('RefreshReviewsEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewsLoaded] when refresh succeeds',
      build: () {
        when(() => mockGetReviews(serviceId: 'service1', page: 1, limit: 20))
            .thenAnswer((_) async => Right(tPaginatedResponse));
        return bloc;
      },
      act: (bloc) {
        bloc.add(const LoadReviewsEvent(serviceId: 'service1', page: 1, limit: 20));
        bloc.add(const RefreshReviewsEvent());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
        const ReviewLoading(),
        ReviewsLoaded(response: tPaginatedResponse, allReviews: [tReview]),
      ],
    );
  });
}

