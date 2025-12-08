// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceCategoryDto _$ServiceCategoryDtoFromJson(Map<String, dynamic> json) =>
    ServiceCategoryDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      displayOrder: (json['display_order'] as num).toInt(),
      serviceCount: (json['service_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ServiceCategoryDtoToJson(ServiceCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon_url': instance.iconUrl,
      'display_order': instance.displayOrder,
      'service_count': instance.serviceCount,
    };

CategoriesResponseDto _$CategoriesResponseDtoFromJson(
        Map<String, dynamic> json) =>
    CategoriesResponseDto(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => ServiceCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$CategoriesResponseDtoToJson(
        CategoriesResponseDto instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'total': instance.total,
    };
