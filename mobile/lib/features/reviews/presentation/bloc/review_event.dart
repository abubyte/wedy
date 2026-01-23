/// Review events using Dart 3 sealed classes for exhaustiveness checking
sealed class ReviewEvent {
  const ReviewEvent();
}

/// Load reviews for a service
final class LoadReviewsEvent extends ReviewEvent {
  final String serviceId;
  final int page;
  final int limit;

  const LoadReviewsEvent({required this.serviceId, this.page = 1, this.limit = 20});
}

/// Load more reviews (pagination)
final class LoadMoreReviewsEvent extends ReviewEvent {
  const LoadMoreReviewsEvent();
}

/// Create a new review
final class CreateReviewEvent extends ReviewEvent {
  final String serviceId;
  final int rating;
  final String? comment;

  const CreateReviewEvent({required this.serviceId, required this.rating, this.comment});
}

/// Update an existing review
final class UpdateReviewEvent extends ReviewEvent {
  final String reviewId;
  final int? rating;
  final String? comment;

  const UpdateReviewEvent({required this.reviewId, this.rating, this.comment});
}

/// Delete a review
final class DeleteReviewEvent extends ReviewEvent {
  final String reviewId;

  const DeleteReviewEvent(this.reviewId);
}

/// Refresh reviews
final class RefreshReviewsEvent extends ReviewEvent {
  const RefreshReviewsEvent();
}

/// Load reviews by user ID
final class LoadUserReviewsEvent extends ReviewEvent {
  final String userId;
  final int page;
  final int limit;

  const LoadUserReviewsEvent({required this.userId, this.page = 1, this.limit = 20});
}

/// Load more user reviews (pagination)
final class LoadMoreUserReviewsEvent extends ReviewEvent {
  const LoadMoreUserReviewsEvent();
}
