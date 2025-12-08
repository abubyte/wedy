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
    return savedServices.map((item) => item.toEntity()).toList();
  }
}
