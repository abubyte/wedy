import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

/// Use case for getting reviews for a service
class GetReviews {
  final ReviewRepository repository;

  GetReviews(this.repository);

  Future<Either<Failure, PaginatedReviewResponse>> call({
    required String serviceId,
    int page = 1,
    int limit = 20,
  }) async {
    if (serviceId.isEmpty) {
      return const Left(ValidationFailure('Service ID cannot be empty'));
    }

    return await repository.getServiceReviews(serviceId: serviceId, page: page, limit: limit);
  }
}
