import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/review_repository.dart';

/// Use case for deleting a review
class DeleteReview {
  final ReviewRepository repository;

  DeleteReview(this.repository);

  Future<Either<Failure, void>> call(String reviewId) async {
    if (reviewId.isEmpty) {
      return const Left(ValidationFailure('Review ID cannot be empty'));
    }

    return await repository.deleteReview(reviewId);
  }
}
