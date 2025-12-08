import 'package:equatable/equatable.dart';
import '../../domain/entities/review.dart';

/// Review states
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

/// Loading state
class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

/// Reviews loaded state
class ReviewsLoaded extends ReviewState {
  final PaginatedReviewResponse response;
  final List<Review> allReviews; // Accumulated list for pagination

  const ReviewsLoaded({required this.response, required this.allReviews});

  @override
  List<Object?> get props => [response, allReviews];
}

/// Review created successfully
class ReviewCreated extends ReviewState {
  final Review review;

  const ReviewCreated(this.review);

  @override
  List<Object?> get props => [review];
}

/// Review updated successfully
class ReviewUpdated extends ReviewState {
  final Review review;

  const ReviewUpdated(this.review);

  @override
  List<Object?> get props => [review];
}

/// Review deleted successfully
class ReviewDeleted extends ReviewState {
  const ReviewDeleted();
}

/// Error state
class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object?> get props => [message];
}

