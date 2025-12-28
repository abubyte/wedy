// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceImageDto _$ServiceImageDtoFromJson(Map<String, dynamic> json) =>
    ServiceImageDto(
      id: json['id'] as String,
      s3Url: json['s3_url'] as String,
      fileName: json['file_name'] as String,
      displayOrder: (json['display_order'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceImageDtoToJson(ServiceImageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      's3_url': instance.s3Url,
      'file_name': instance.fileName,
      'display_order': instance.displayOrder,
    };

MerchantBasicInfoDto _$MerchantBasicInfoDtoFromJson(
        Map<String, dynamic> json) =>
    MerchantBasicInfoDto(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      overallRating: (json['overall_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      locationRegion: json['location_region'] as String,
      isVerified: json['is_verified'] as bool,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$MerchantBasicInfoDtoToJson(
        MerchantBasicInfoDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_name': instance.businessName,
      'overall_rating': instance.overallRating,
      'total_reviews': instance.totalReviews,
      'location_region': instance.locationRegion,
      'is_verified': instance.isVerified,
      'avatar_url': instance.avatarUrl,
    };

ServiceListItemDto _$ServiceListItemDtoFromJson(Map<String, dynamic> json) =>
    ServiceListItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      locationRegion: json['location_region'] as String,
      overallRating: (json['overall_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      viewCount: (json['view_count'] as num).toInt(),
      likeCount: (json['like_count'] as num).toInt(),
      saveCount: (json['save_count'] as num).toInt(),
      createdAt: json['created_at'] as String,
      merchant: MerchantBasicInfoDto.fromJson(
          json['merchant'] as Map<String, dynamic>),
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name'] as String,
      mainImageUrl: json['main_image_url'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
    );

Map<String, dynamic> _$ServiceListItemDtoToJson(ServiceListItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'location_region': instance.locationRegion,
      'overall_rating': instance.overallRating,
      'total_reviews': instance.totalReviews,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'save_count': instance.saveCount,
      'created_at': instance.createdAt,
      'merchant': instance.merchant,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'main_image_url': instance.mainImageUrl,
      'is_featured': instance.isFeatured,
      'is_liked': instance.isLiked,
      'is_saved': instance.isSaved,
    };

ServiceDetailDto _$ServiceDetailDtoFromJson(Map<String, dynamic> json) =>
    ServiceDetailDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      locationRegion: json['location_region'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      viewCount: (json['view_count'] as num).toInt(),
      likeCount: (json['like_count'] as num).toInt(),
      saveCount: (json['save_count'] as num).toInt(),
      shareCount: (json['share_count'] as num).toInt(),
      overallRating: (json['overall_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      merchant: MerchantBasicInfoDto.fromJson(
          json['merchant'] as Map<String, dynamic>),
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name'] as String,
      images: (json['images'] as List<dynamic>)
          .map((e) => ServiceImageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredUntil: json['featured_until'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
    );

Map<String, dynamic> _$ServiceDetailDtoToJson(ServiceDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'location_region': instance.locationRegion,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'save_count': instance.saveCount,
      'share_count': instance.shareCount,
      'overall_rating': instance.overallRating,
      'total_reviews': instance.totalReviews,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'merchant': instance.merchant,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'images': instance.images,
      'is_featured': instance.isFeatured,
      'featured_until': instance.featuredUntil,
      'is_liked': instance.isLiked,
      'is_saved': instance.isSaved,
    };

PaginatedServiceResponseDto _$PaginatedServiceResponseDtoFromJson(
        Map<String, dynamic> json) =>
    PaginatedServiceResponseDto(
      services: (json['services'] as List<dynamic>)
          .map((e) => ServiceListItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      totalPages: (json['total_pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedServiceResponseDtoToJson(
        PaginatedServiceResponseDto instance) =>
    <String, dynamic>{
      'services': instance.services,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'has_more': instance.hasMore,
      'total_pages': instance.totalPages,
    };

ServiceInteractionResponseDto _$ServiceInteractionResponseDtoFromJson(
        Map<String, dynamic> json) =>
    ServiceInteractionResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      newCount: (json['new_count'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$ServiceInteractionResponseDtoToJson(
        ServiceInteractionResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'new_count': instance.newCount,
      'is_active': instance.isActive,
    };

ServiceCreateRequestDto _$ServiceCreateRequestDtoFromJson(
        Map<String, dynamic> json) =>
    ServiceCreateRequestDto(
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      locationRegion: json['location_region'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ServiceCreateRequestDtoToJson(
        ServiceCreateRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category_id': instance.categoryId,
      'price': instance.price,
      'location_region': instance.locationRegion,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

ServiceUpdateRequestDto _$ServiceUpdateRequestDtoFromJson(
        Map<String, dynamic> json) =>
    ServiceUpdateRequestDto(
      name: json['name'] as String?,
      description: json['description'] as String?,
      categoryId: (json['category_id'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
      locationRegion: json['location_region'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ServiceUpdateRequestDtoToJson(
        ServiceUpdateRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category_id': instance.categoryId,
      'price': instance.price,
      'location_region': instance.locationRegion,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

MerchantServiceDto _$MerchantServiceDtoFromJson(Map<String, dynamic> json) =>
    MerchantServiceDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name'] as String,
      price: (json['price'] as num).toDouble(),
      locationRegion: json['location_region'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool,
      viewCount: (json['view_count'] as num).toInt(),
      likeCount: (json['like_count'] as num).toInt(),
      saveCount: (json['save_count'] as num).toInt(),
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      overallRating: (json['overall_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      mainImageUrl: json['main_image_url'] as String?,
      imagesCount: (json['images_count'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredUntil: json['featured_until'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$MerchantServiceDtoToJson(MerchantServiceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'price': instance.price,
      'location_region': instance.locationRegion,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'is_active': instance.isActive,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'save_count': instance.saveCount,
      'share_count': instance.shareCount,
      'overall_rating': instance.overallRating,
      'total_reviews': instance.totalReviews,
      'main_image_url': instance.mainImageUrl,
      'images_count': instance.imagesCount,
      'is_featured': instance.isFeatured,
      'featured_until': instance.featuredUntil,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

ImageUploadResponseDto _$ImageUploadResponseDtoFromJson(
        Map<String, dynamic> json) =>
    ImageUploadResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      imageId: json['image_id'] as String?,
      s3Url: json['s3_url'] as String?,
      presignedUrl: json['presigned_url'] as String?,
    );

Map<String, dynamic> _$ImageUploadResponseDtoToJson(
        ImageUploadResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'image_id': instance.imageId,
      's3_url': instance.s3Url,
      'presigned_url': instance.presignedUrl,
    };

MerchantServicesResponseDto _$MerchantServicesResponseDtoFromJson(
        Map<String, dynamic> json) =>
    MerchantServicesResponseDto(
      services: (json['services'] as List<dynamic>)
          .map((e) => MerchantServiceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeCount: (json['active_count'] as num).toInt(),
      inactiveCount: (json['inactive_count'] as num).toInt(),
    );

Map<String, dynamic> _$MerchantServicesResponseDtoToJson(
        MerchantServicesResponseDto instance) =>
    <String, dynamic>{
      'services': instance.services,
      'active_count': instance.activeCount,
      'inactive_count': instance.inactiveCount,
    };
