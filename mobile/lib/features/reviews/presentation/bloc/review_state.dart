import '../../domain/entities/review.dart';

/// Review states using Dart 3 sealed classes for exhaustiveness checking
sealed class ReviewState {
  const ReviewState();
}

/// Initial state
final class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

/// Loading state
final class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

/// Reviews loaded state with pagination support
final class ReviewsLoaded extends ReviewState {
  final PaginatedReviewResponse response;
  final List<Review> allReviews;
  final bool hasMore;

  const ReviewsLoaded({required this.response, required this.allReviews, this.hasMore = true});

  ReviewsLoaded copyWith({PaginatedReviewResponse? response, List<Review>? allReviews, bool? hasMore}) {
    return ReviewsLoaded(
      response: response ?? this.response,
      allReviews: allReviews ?? this.allReviews,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Review created successfully
final class ReviewCreated extends ReviewState {
  final Review review;

  const ReviewCreated(this.review);
}

/// Review updated successfully
final class ReviewUpdated extends ReviewState {
  final Review review;

  const ReviewUpdated(this.review);
}

/// Review deleted successfully
final class ReviewDeleted extends ReviewState {
  const ReviewDeleted();
}

/// Error state
final class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);
}
