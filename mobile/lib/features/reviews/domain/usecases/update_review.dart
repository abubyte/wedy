import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

/// Use case for updating a review
class UpdateReview {
  final ReviewRepository repository;

  UpdateReview(this.repository);

  Future<Either<Failure, Review>> call({required String reviewId, int? rating, String? comment}) async {
    if (reviewId.isEmpty) {
      return const Left(ValidationFailure('Review ID cannot be empty'));
    }

    if (rating != null && (rating < 1 || rating > 5)) {
      return const Left(ValidationFailure('Rating must be between 1 and 5'));
    }

    return await repository.updateReview(reviewId: reviewId, rating: rating, comment: comment);
  }
}
