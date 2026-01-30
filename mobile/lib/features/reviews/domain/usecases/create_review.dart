import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

/// Use case for creating a review
class CreateReview {
  final ReviewRepository repository;

  CreateReview(this.repository);

  Future<Either<Failure, Review>> call({required String serviceId, required int rating, String? comment}) async {
    if (serviceId.isEmpty) {
      return const Left(ValidationFailure('Service ID cannot be empty'));
    }

    if (rating < 1 || rating > 5) {
      return const Left(ValidationFailure('Rating must be between 1 and 5'));
    }

    return await repository.createReview(serviceId: serviceId, rating: rating, comment: comment);
  }
}
