import 'package:equatable/equatable.dart';

/// Review entity (domain layer)
class Review extends Equatable {
  final String id; // UUID as string
  final String serviceId; // 9-digit string
  final String userId; // 9-digit string
  final String merchantId; // UUID as string
  final int rating; // 1-5
  final String? comment;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReviewUser? user;
  final ReviewService? service;

  const Review({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.merchantId,
    required this.rating,
    this.comment,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.service,
  });

  @override
  List<Object?> get props => [
        id,
        serviceId,
        userId,
        merchantId,
        rating,
        comment,
        isActive,
        createdAt,
        updatedAt,
        user,
        service,
      ];
}

/// User information in review
class ReviewUser extends Equatable {
  final String id; // 9-digit string
  final String name;
  final String? avatarUrl;

  const ReviewUser({required this.id, required this.name, this.avatarUrl});

  @override
  List<Object?> get props => [id, name, avatarUrl];
}

/// Service information in review
class ReviewService extends Equatable {
  final String id; // 9-digit string
  final String name;

  const ReviewService({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Paginated review response
class PaginatedReviewResponse extends Equatable {
  final List<Review> reviews;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final int totalPages;

  const PaginatedReviewResponse({
    required this.reviews,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [reviews, total, page, limit, hasMore, totalPages];
}
