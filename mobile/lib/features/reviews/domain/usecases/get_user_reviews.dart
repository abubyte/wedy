import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

/// Use case for getting reviews by user ID
class GetUserReviews {
  final ReviewRepository repository;

  GetUserReviews(this.repository);

  Future<Either<Failure, PaginatedReviewResponse>> call({required String userId, int page = 1, int limit = 20}) async {
    if (userId.isEmpty) {
      return const Left(ValidationFailure('User ID cannot be empty'));
    }

    return await repository.getUserReviews(userId: userId, page: page, limit: limit);
  }
}
