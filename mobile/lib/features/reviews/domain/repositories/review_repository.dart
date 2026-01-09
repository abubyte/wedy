import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/review.dart';

/// Review repository interface (domain layer)
abstract class ReviewRepository {
  /// Get reviews for a specific service
  Future<Either<Failure, PaginatedReviewResponse>> getServiceReviews({
    required String serviceId,
    int page = 1,
    int limit = 20,
  });

  /// Get reviews by user ID
  Future<Either<Failure, PaginatedReviewResponse>> getUserReviews({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  /// Create a new review
  Future<Either<Failure, Review>> createReview({
    required String serviceId,
    required int rating,
    String? comment,
  });

  /// Update an existing review
  Future<Either<Failure, Review>> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  });

  /// Delete a review
  Future<Either<Failure, void>> deleteReview(String reviewId);
}

