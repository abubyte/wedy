// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_interaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInteractionItemDto _$UserInteractionItemDtoFromJson(Map<String, dynamic> json) => UserInteractionItemDto(
  interactionType: json['interaction_type'] as String,
  interactedAt: json['interacted_at'] as String,
  service: ServiceListItemDto.fromJson(json['service'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserInteractionItemDtoToJson(UserInteractionItemDto instance) => <String, dynamic>{
  'interaction_type': instance.interactionType,
  'interacted_at': instance.interactedAt,
  'service': instance.service,
};

UserInteractionsResponseDto _$UserInteractionsResponseDtoFromJson(Map<String, dynamic> json) =>
    UserInteractionsResponseDto(
      likedServices: (json['liked_services'] as List<dynamic>)
          .map((e) => UserInteractionItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      savedServices: (json['saved_services'] as List<dynamic>)
          .map((e) => UserInteractionItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalLiked: (json['total_liked'] as num).toInt(),
      totalSaved: (json['total_saved'] as num).toInt(),
    );

Map<String, dynamic> _$UserInteractionsResponseDtoToJson(UserInteractionsResponseDto instance) => <String, dynamic>{
  'liked_services': instance.likedServices,
  'saved_services': instance.savedServices,
  'total_liked': instance.totalLiked,
  'total_saved': instance.totalSaved,
};
