// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewUserDto _$ReviewUserDtoFromJson(Map<String, dynamic> json) =>
    ReviewUserDto(id: json['id'] as String, name: json['name'] as String, avatarUrl: json['avatar_url'] as String?);

Map<String, dynamic> _$ReviewUserDtoToJson(ReviewUserDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar_url': instance.avatarUrl,
};

ReviewServiceDto _$ReviewServiceDtoFromJson(Map<String, dynamic> json) =>
    ReviewServiceDto(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$ReviewServiceDtoToJson(ReviewServiceDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

ReviewDto _$ReviewDtoFromJson(Map<String, dynamic> json) => ReviewDto(
  id: json['id'] as String,
  serviceId: json['service_id'] as String,
  userId: json['user_id'] as String,
  merchantId: json['merchant_id'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  user: json['user'] == null ? null : ReviewUserDto.fromJson(json['user'] as Map<String, dynamic>),
  service: json['service'] == null ? null : ReviewServiceDto.fromJson(json['service'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReviewDtoToJson(ReviewDto instance) => <String, dynamic>{
  'id': instance.id,
  'service_id': instance.serviceId,
  'user_id': instance.userId,
  'merchant_id': instance.merchantId,
  'rating': instance.rating,
  'comment': instance.comment,
  'is_active': instance.isActive,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'user': instance.user,
  'service': instance.service,
};

PaginatedReviewResponseDto _$PaginatedReviewResponseDtoFromJson(Map<String, dynamic> json) =>
    PaginatedReviewResponseDto(
      reviews: (json['reviews'] as List<dynamic>).map((e) => ReviewDto.fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      totalPages: (json['total_pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedReviewResponseDtoToJson(PaginatedReviewResponseDto instance) => <String, dynamic>{
  'reviews': instance.reviews,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'has_more': instance.hasMore,
  'total_pages': instance.totalPages,
};

ReviewCreateRequestDto _$ReviewCreateRequestDtoFromJson(Map<String, dynamic> json) => ReviewCreateRequestDto(
  serviceId: json['service_id'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$ReviewCreateRequestDtoToJson(ReviewCreateRequestDto instance) => <String, dynamic>{
  'service_id': instance.serviceId,
  'rating': instance.rating,
  'comment': instance.comment,
};

ReviewUpdateRequestDto _$ReviewUpdateRequestDtoFromJson(Map<String, dynamic> json) =>
    ReviewUpdateRequestDto(rating: (json['rating'] as num?)?.toInt(), comment: json['comment'] as String?);

Map<String, dynamic> _$ReviewUpdateRequestDtoToJson(ReviewUpdateRequestDto instance) => <String, dynamic>{
  'rating': instance.rating,
  'comment': instance.comment,
};
