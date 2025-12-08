import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/review.dart';

part 'review_dto.g.dart';

/// Review DTOs for API communication

@JsonSerializable()
class ReviewUserDto {
  final String id;
  final String name;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  ReviewUserDto({required this.id, required this.name, this.avatarUrl});

  factory ReviewUserDto.fromJson(Map<String, dynamic> json) => _$ReviewUserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewUserDtoToJson(this);

  ReviewUser toEntity() {
    return ReviewUser(id: id, name: name, avatarUrl: avatarUrl);
  }
}

@JsonSerializable()
class ReviewServiceDto {
  final String id;
  final String name;

  ReviewServiceDto({required this.id, required this.name});

  factory ReviewServiceDto.fromJson(Map<String, dynamic> json) => _$ReviewServiceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewServiceDtoToJson(this);

  ReviewService toEntity() {
    return ReviewService(id: id, name: name);
  }
}

@JsonSerializable()
class ReviewDto {
  final String id; // UUID as string
  @JsonKey(name: 'service_id')
  final String serviceId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'merchant_id')
  final String merchantId;
  final int rating;
  final String? comment;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final ReviewUserDto? user;
  final ReviewServiceDto? service;

  ReviewDto({
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

  factory ReviewDto.fromJson(Map<String, dynamic> json) => _$ReviewDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewDtoToJson(this);

  Review toEntity() {
    return Review(
      id: id,
      serviceId: serviceId,
      userId: userId,
      merchantId: merchantId,
      rating: rating,
      comment: comment,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      user: user?.toEntity(),
      service: service?.toEntity(),
    );
  }
}

@JsonSerializable()
class PaginatedReviewResponseDto {
  final List<ReviewDto> reviews;
  final int total;
  final int page;
  final int limit;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  PaginatedReviewResponseDto({
    required this.reviews,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.totalPages,
  });

  factory PaginatedReviewResponseDto.fromJson(Map<String, dynamic> json) => _$PaginatedReviewResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedReviewResponseDtoToJson(this);

  PaginatedReviewResponse toEntity() {
    return PaginatedReviewResponse(
      reviews: reviews.map((dto) => dto.toEntity()).toList(),
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
      totalPages: totalPages,
    );
  }
}

@JsonSerializable()
class ReviewCreateRequestDto {
  @JsonKey(name: 'service_id')
  final String serviceId;
  final int rating;
  final String? comment;

  ReviewCreateRequestDto({required this.serviceId, required this.rating, this.comment});

  factory ReviewCreateRequestDto.fromJson(Map<String, dynamic> json) => _$ReviewCreateRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewCreateRequestDtoToJson(this);
}

@JsonSerializable()
class ReviewUpdateRequestDto {
  final int? rating;
  final String? comment;

  ReviewUpdateRequestDto({this.rating, this.comment});

  factory ReviewUpdateRequestDto.fromJson(Map<String, dynamic> json) => _$ReviewUpdateRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewUpdateRequestDtoToJson(this);
}

