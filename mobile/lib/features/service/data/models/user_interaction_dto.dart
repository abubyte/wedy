import 'package:json_annotation/json_annotation.dart';
import 'service_dto.dart';
import '../../domain/entities/service.dart';

part 'user_interaction_dto.g.dart';

@JsonSerializable()
class UserInteractionItemDto {
  @JsonKey(name: 'interaction_type')
  final String interactionType;
  @JsonKey(name: 'interacted_at')
  final String interactedAt;
  final ServiceListItemDto service;

  UserInteractionItemDto({required this.interactionType, required this.interactedAt, required this.service});

  factory UserInteractionItemDto.fromJson(Map<String, dynamic> json) => _$UserInteractionItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInteractionItemDtoToJson(this);

  ServiceListItem toEntity() {
    return service.toEntity();
  }
}

@JsonSerializable()
class UserInteractionsResponseDto {
  @JsonKey(name: 'liked_services')
  final List<UserInteractionItemDto> likedServices;
  @JsonKey(name: 'saved_services')
  final List<UserInteractionItemDto> savedServices;
  @JsonKey(name: 'total_liked')
  final int totalLiked;
  @JsonKey(name: 'total_saved')
  final int totalSaved;

  UserInteractionsResponseDto({
    required this.likedServices,
    required this.savedServices,
    required this.totalLiked,
    required this.totalSaved,
  });

  factory UserInteractionsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserInteractionsResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInteractionsResponseDtoToJson(this);

  List<ServiceListItem> toSavedServicesEntity() {
    return savedServices.map((item) {
      final service = item.toEntity();
      // Ensure all saved services are marked as saved
      return ServiceListItem(
        id: service.id,
        name: service.name,
        description: service.description,
        price: service.price,
        locationRegion: service.locationRegion,
        overallRating: service.overallRating,
        totalReviews: service.totalReviews,
        viewCount: service.viewCount,
        likeCount: service.likeCount,
        saveCount: service.saveCount,
        createdAt: service.createdAt,
        merchant: service.merchant,
        categoryId: service.categoryId,
        categoryName: service.categoryName,
        mainImageUrl: service.mainImageUrl,
        isFeatured: service.isFeatured,
        isLiked: service.isLiked,
        isSaved: true, // All services in saved list should be marked as saved
      );
    }).toList();
  }

  List<ServiceListItem> toLikedServicesEntity() {
    return likedServices.map((item) {
      final service = item.toEntity();
      // Ensure all liked services are marked as liked
      return ServiceListItem(
        id: service.id,
        name: service.name,
        description: service.description,
        price: service.price,
        locationRegion: service.locationRegion,
        overallRating: service.overallRating,
        totalReviews: service.totalReviews,
        viewCount: service.viewCount,
        likeCount: service.likeCount,
        saveCount: service.saveCount,
        createdAt: service.createdAt,
        merchant: service.merchant,
        categoryId: service.categoryId,
        categoryName: service.categoryName,
        mainImageUrl: service.mainImageUrl,
        isFeatured: service.isFeatured,
        isLiked: true, // All services in liked list should be marked as liked
        isSaved: service.isSaved,
      );
    }).toList();
  }
}
