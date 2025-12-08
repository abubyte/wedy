import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:wedy/features/reviews/data/models/review_dto.dart';
import 'package:wedy/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:wedy/features/reviews/domain/entities/review.dart' show Review, PaginatedReviewResponse;

class MockReviewRemoteDataSource extends Mock implements ReviewRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReviewRepositoryImpl repository;
  late MockReviewRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(ReviewCreateRequestDto(serviceId: '', rating: 1));
    registerFallbackValue(ReviewUpdateRequestDto());
  });

  setUp(() {
    mockRemoteDataSource = MockReviewRemoteDataSource();
    repository = ReviewRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  final tReviewUserDto = ReviewUserDto(id: 'user1', name: 'Test User', avatarUrl: 'https://example.com/avatar.jpg');
  final tReviewServiceDto = ReviewServiceDto(id: 'service1', name: 'Test Service');
  final tReviewDto = ReviewDto(
    id: 'review1',
    serviceId: 'service1',
    userId: 'user1',
    merchantId: 'merchant1',
    rating: 5,
    comment: 'Great service!',
    isActive: true,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    user: tReviewUserDto,
    service: tReviewServiceDto,
  );

  final tPaginatedResponseDto = PaginatedReviewResponseDto(
    reviews: [tReviewDto],
    total: 1,
    page: 1,
    limit: 20,
    hasMore: false,
    totalPages: 1,
  );

  group('getServiceReviews', () {
    test('should return reviews when API call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20))
          .thenAnswer((_) async => tPaginatedResponseDto);

      // Act
      final result = await repository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20);

      // Assert
      expect(result, isA<Right<Failure, PaginatedReviewResponse>>());
      verify(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20)).called(1);
    });

    test('should return NetworkFailure when there is no internet connection', () async {
      // Arrange
      when(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act
      final result = await repository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20);

      // Assert
      expect(result, isA<Left<Failure, PaginatedReviewResponse>>());
      expect((result as Left).value, isA<NetworkFailure>());
      verify(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20)).called(1);
    });

    test('should return ServerFailure when API returns 500', () async {
      // Arrange
      when(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(statusCode: 500, requestOptions: RequestOptions(path: '')),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20);

      // Assert
      expect(result, isA<Left<Failure, PaginatedReviewResponse>>());
      expect((result as Left).value, isA<ServerFailure>());
      verify(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20)).called(1);
    });

    test('should return NotFoundFailure when API returns 404', () async {
      // Arrange
      when(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(statusCode: 404, requestOptions: RequestOptions(path: '')),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.getServiceReviews(serviceId: 'service1', page: 1, limit: 20);

      // Assert
      expect(result, isA<Left<Failure, PaginatedReviewResponse>>());
      expect((result as Left).value, isA<NotFoundFailure>());
      verify(() => mockRemoteDataSource.getServiceReviews('service1', page: 1, limit: 20)).called(1);
    });
  });

  group('createReview', () {
    test('should return review when API call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.createReview(any())).thenAnswer((_) async => tReviewDto);

      // Act
      final result = await repository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!');

      // Assert
      expect(result, isA<Right<Failure, Review>>());
      verify(() => mockRemoteDataSource.createReview(any())).called(1);
    });

    test('should return ValidationFailure when API returns 409', () async {
      // Arrange
      when(() => mockRemoteDataSource.createReview(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          statusCode: 409,
          data: {'detail': 'You have already reviewed this service.'},
          requestOptions: RequestOptions(path: ''),
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!');

      // Assert
      expect(result, isA<Left<Failure, Review>>());
      expect((result as Left).value, isA<ValidationFailure>());
      verify(() => mockRemoteDataSource.createReview(any())).called(1);
    });

    test('should return AuthFailure when API returns 401', () async {
      // Arrange
      when(() => mockRemoteDataSource.createReview(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(statusCode: 401, requestOptions: RequestOptions(path: '')),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.createReview(serviceId: 'service1', rating: 5, comment: 'Great service!');

      // Assert
      expect(result, isA<Left<Failure, Review>>());
      expect((result as Left).value, isA<AuthFailure>());
      verify(() => mockRemoteDataSource.createReview(any())).called(1);
    });
  });

  group('updateReview', () {
    test('should return updated review when API call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateReview(any(), any())).thenAnswer((_) async => tReviewDto);

      // Act
      final result = await repository.updateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment');

      // Assert
      expect(result, isA<Right<Failure, Review>>());
      verify(() => mockRemoteDataSource.updateReview(any(), any())).called(1);
    });

    test('should return NotFoundFailure when API returns 404', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateReview(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(statusCode: 404, requestOptions: RequestOptions(path: '')),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.updateReview(reviewId: 'review1', rating: 4, comment: 'Updated comment');

      // Assert
      expect(result, isA<Left<Failure, Review>>());
      expect((result as Left).value, isA<NotFoundFailure>());
      verify(() => mockRemoteDataSource.updateReview(any(), any())).called(1);
    });
  });

  group('deleteReview', () {
    test('should return void when API call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.deleteReview('review1')).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteReview('review1');

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.deleteReview('review1')).called(1);
    });

    test('should return NotFoundFailure when API returns 404', () async {
      // Arrange
      when(() => mockRemoteDataSource.deleteReview('review1')).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(statusCode: 404, requestOptions: RequestOptions(path: '')),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.deleteReview('review1');

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, isA<NotFoundFailure>());
      verify(() => mockRemoteDataSource.deleteReview('review1')).called(1);
    });
  });
}

