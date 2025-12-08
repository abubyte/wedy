import 'package:equatable/equatable.dart';

/// Review events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

/// Load reviews for a service
class LoadReviewsEvent extends ReviewEvent {
  final String serviceId;
  final int page;
  final int limit;

  const LoadReviewsEvent({required this.serviceId, this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [serviceId, page, limit];
}

/// Load more reviews (pagination)
class LoadMoreReviewsEvent extends ReviewEvent {
  const LoadMoreReviewsEvent();
}

/// Create a new review
class CreateReviewEvent extends ReviewEvent {
  final String serviceId;
  final int rating;
  final String? comment;

  const CreateReviewEvent({required this.serviceId, required this.rating, this.comment});

  @override
  List<Object?> get props => [serviceId, rating, comment];
}

/// Update an existing review
class UpdateReviewEvent extends ReviewEvent {
  final String reviewId;
  final int? rating;
  final String? comment;

  const UpdateReviewEvent({required this.reviewId, this.rating, this.comment});

  @override
  List<Object?> get props => [reviewId, rating, comment];
}

/// Delete a review
class DeleteReviewEvent extends ReviewEvent {
  final String reviewId;

  const DeleteReviewEvent(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

/// Refresh reviews
class RefreshReviewsEvent extends ReviewEvent {
  const RefreshReviewsEvent();
}

