import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';

part 'service_dto.g.dart';

/// Service DTOs for API communication

@JsonSerializable()
class ServiceImageDto {
  final String id;
  @JsonKey(name: 's3_url')
  final String s3Url;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'display_order')
  final int displayOrder;

  ServiceImageDto({required this.id, required this.s3Url, required this.fileName, required this.displayOrder});

  factory ServiceImageDto.fromJson(Map<String, dynamic> json) => _$ServiceImageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceImageDtoToJson(this);

  ServiceImage toEntity() {
    return ServiceImage(id: id, s3Url: s3Url, fileName: fileName, displayOrder: displayOrder);
  }
}

@JsonSerializable()
class MerchantBasicInfoDto {
  final String id;
  @JsonKey(name: 'business_name')
  final String businessName;
  @JsonKey(name: 'overall_rating')
  final double overallRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'location_region')
  final String locationRegion;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  MerchantBasicInfoDto({
    required this.id,
    required this.businessName,
    required this.overallRating,
    required this.totalReviews,
    required this.locationRegion,
    required this.isVerified,
    this.avatarUrl,
  });

  factory MerchantBasicInfoDto.fromJson(Map<String, dynamic> json) => _$MerchantBasicInfoDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantBasicInfoDtoToJson(this);

  MerchantBasicInfo toEntity() {
    return MerchantBasicInfo(
      id: id,
      businessName: businessName,
      overallRating: overallRating,
      totalReviews: totalReviews,
      locationRegion: locationRegion,
      isVerified: isVerified,
      avatarUrl: avatarUrl,
    );
  }
}

@JsonSerializable()
class ServiceListItemDto {
  final String id;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'location_region')
  final String locationRegion;
  @JsonKey(name: 'overall_rating')
  final double overallRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'like_count')
  final int likeCount;
  @JsonKey(name: 'save_count')
  final int saveCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final MerchantBasicInfoDto merchant;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  @JsonKey(name: 'main_image_url')
  final String? mainImageUrl;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;

  ServiceListItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.locationRegion,
    required this.overallRating,
    required this.totalReviews,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    required this.createdAt,
    required this.merchant,
    required this.categoryId,
    required this.categoryName,
    this.mainImageUrl,
    this.isFeatured = false,
  });

  factory ServiceListItemDto.fromJson(Map<String, dynamic> json) => _$ServiceListItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceListItemDtoToJson(this);

  ServiceListItem toEntity() {
    return ServiceListItem(
      id: id,
      name: name,
      description: description,
      price: price,
      locationRegion: locationRegion,
      overallRating: overallRating,
      totalReviews: totalReviews,
      viewCount: viewCount,
      likeCount: likeCount,
      saveCount: saveCount,
      createdAt: DateTime.parse(createdAt),
      merchant: merchant.toEntity(),
      categoryId: categoryId,
      categoryName: categoryName,
      mainImageUrl: mainImageUrl,
      isFeatured: isFeatured,
    );
  }
}

@JsonSerializable()
class ServiceDetailDto {
  final String id;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'location_region')
  final String locationRegion;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'like_count')
  final int likeCount;
  @JsonKey(name: 'save_count')
  final int saveCount;
  @JsonKey(name: 'share_count')
  final int shareCount;
  @JsonKey(name: 'overall_rating')
  final double overallRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final MerchantBasicInfoDto merchant;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  final List<ServiceImageDto> images;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'featured_until')
  final String? featuredUntil;

  ServiceDetailDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.locationRegion,
    this.latitude,
    this.longitude,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    required this.shareCount,
    required this.overallRating,
    required this.totalReviews,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.merchant,
    required this.categoryId,
    required this.categoryName,
    required this.images,
    this.isFeatured = false,
    this.featuredUntil,
  });

  factory ServiceDetailDto.fromJson(Map<String, dynamic> json) => _$ServiceDetailDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceDetailDtoToJson(this);

  Service toEntity() {
    return Service(
      id: id,
      name: name,
      description: description,
      price: price,
      locationRegion: locationRegion,
      latitude: latitude,
      longitude: longitude,
      viewCount: viewCount,
      likeCount: likeCount,
      saveCount: saveCount,
      shareCount: shareCount,
      overallRating: overallRating,
      totalReviews: totalReviews,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      merchant: merchant.toEntity(),
      categoryId: categoryId,
      categoryName: categoryName,
      images: images.map((img) => img.toEntity()).toList(),
      isFeatured: isFeatured,
      featuredUntil: featuredUntil != null ? DateTime.parse(featuredUntil!) : null,
    );
  }
}

@JsonSerializable()
class PaginatedServiceResponseDto {
  final List<ServiceListItemDto> services;
  final int total;
  final int page;
  final int limit;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  PaginatedServiceResponseDto({
    required this.services,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.totalPages,
  });

  factory PaginatedServiceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedServiceResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedServiceResponseDtoToJson(this);

  PaginatedServiceResponse toEntity() {
    return PaginatedServiceResponse(
      services: services.map((s) => s.toEntity()).toList(),
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
      totalPages: totalPages,
    );
  }
}

@JsonSerializable()
class ServiceInteractionResponseDto {
  final bool success;
  final String message;
  @JsonKey(name: 'new_count')
  final int newCount;

  ServiceInteractionResponseDto({required this.success, required this.message, required this.newCount});

  factory ServiceInteractionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ServiceInteractionResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceInteractionResponseDtoToJson(this);

  ServiceInteractionResponse toEntity() {
    return ServiceInteractionResponse(success: success, message: message, newCount: newCount);
  }
}

/// Request DTO for creating a service
@JsonSerializable()
class ServiceCreateRequestDto {
  final String name;
  final String description;
  @JsonKey(name: 'category_id')
  final int categoryId;
  final double price;
  @JsonKey(name: 'location_region')
  final String locationRegion;
  final double? latitude;
  final double? longitude;

  ServiceCreateRequestDto({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.locationRegion,
    this.latitude,
    this.longitude,
  });

  factory ServiceCreateRequestDto.fromJson(Map<String, dynamic> json) => _$ServiceCreateRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceCreateRequestDtoToJson(this);
}

/// Request DTO for updating a service
@JsonSerializable()
class ServiceUpdateRequestDto {
  final String? name;
  final String? description;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  final double? price;
  @JsonKey(name: 'location_region')
  final String? locationRegion;
  final double? latitude;
  final double? longitude;

  ServiceUpdateRequestDto({
    this.name,
    this.description,
    this.categoryId,
    this.price,
    this.locationRegion,
    this.latitude,
    this.longitude,
  });

  factory ServiceUpdateRequestDto.fromJson(Map<String, dynamic> json) => _$ServiceUpdateRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceUpdateRequestDtoToJson(this);
}

/// Response DTO for merchant service (simplified version)
@JsonSerializable()
class MerchantServiceDto {
  final String id;
  final String name;
  final String description;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  final double price;
  @JsonKey(name: 'location_region')
  final String locationRegion;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'like_count')
  final int likeCount;
  @JsonKey(name: 'save_count')
  final int saveCount;
  @JsonKey(name: 'share_count')
  final int shareCount;
  @JsonKey(name: 'overall_rating')
  final double overallRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'main_image_url')
  final String? mainImageUrl;
  @JsonKey(name: 'images_count')
  final int imagesCount;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'featured_until')
  final String? featuredUntil;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  MerchantServiceDto({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.locationRegion,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    this.shareCount = 0,
    required this.overallRating,
    required this.totalReviews,
    this.mainImageUrl,
    this.imagesCount = 0,
    this.isFeatured = false,
    this.featuredUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantServiceDto.fromJson(Map<String, dynamic> json) => _$MerchantServiceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantServiceDtoToJson(this);

  MerchantService toEntity() {
    return MerchantService(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      price: price,
      locationRegion: locationRegion,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
      viewCount: viewCount,
      likeCount: likeCount,
      saveCount: saveCount,
      overallRating: overallRating,
      totalReviews: totalReviews,
      mainImageUrl: mainImageUrl,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Convert to Service entity (for create/update responses)
  /// Uses default values for merchant and images since they're not in MerchantServiceResponse
  Service toServiceEntity() {
    return Service(
      id: id,
      name: name,
      description: description,
      price: price,
      locationRegion: locationRegion,
      latitude: latitude,
      longitude: longitude,
      viewCount: viewCount,
      likeCount: likeCount,
      saveCount: saveCount,
      shareCount: shareCount,
      overallRating: overallRating,
      totalReviews: totalReviews,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      merchant: MerchantBasicInfo(
        id: '', // Not available in MerchantServiceResponse
        businessName: '',
        overallRating: 0.0,
        totalReviews: 0,
        locationRegion: locationRegion,
        isVerified: false,
        avatarUrl: null,
      ),
      categoryId: categoryId,
      categoryName: categoryName,
      images: [], // Images are uploaded separately
      isFeatured: isFeatured,
      featuredUntil: (featuredUntil != null && featuredUntil!.isNotEmpty) ? DateTime.parse(featuredUntil!) : null,
    );
  }
}

/// Response DTO for image upload
@JsonSerializable()
class ImageUploadResponseDto {
  final bool success;
  final String message;
  @JsonKey(name: 'image_id')
  final String? imageId;
  @JsonKey(name: 's3_url')
  final String? s3Url;
  @JsonKey(name: 'presigned_url')
  final String? presignedUrl;

  ImageUploadResponseDto({required this.success, required this.message, this.imageId, this.s3Url, this.presignedUrl});

  factory ImageUploadResponseDto.fromJson(Map<String, dynamic> json) => _$ImageUploadResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ImageUploadResponseDtoToJson(this);
}

/// Response DTO for merchant services list
@JsonSerializable()
class MerchantServicesResponseDto {
  final List<MerchantServiceDto> services;
  @JsonKey(name: 'active_count')
  final int activeCount;
  @JsonKey(name: 'inactive_count')
  final int inactiveCount;

  MerchantServicesResponseDto({required this.services, required this.activeCount, required this.inactiveCount});

  factory MerchantServicesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MerchantServicesResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantServicesResponseDtoToJson(this);

  MerchantServicesResponse toEntity() {
    return MerchantServicesResponse(
      services: services.map((s) => s.toEntity()).toList(),
      activeCount: activeCount,
      inactiveCount: inactiveCount,
    );
  }
}
