import 'package:json_annotation/json_annotation.dart';
import 'package:wedy/features/category/domain/entities/category.dart';

part 'category_dto.g.dart';

/// Service category DTO
@JsonSerializable()
class ServiceCategoryDto {
  const ServiceCategoryDto({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.displayOrder,
    this.serviceCount = 0,
  });

  final int id;
  final String name;
  @JsonKey(name: 'description')
  final String? description;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'service_count')
  final int serviceCount;

  factory ServiceCategoryDto.fromJson(Map<String, dynamic> json) => _$ServiceCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCategoryDtoToJson(this);

  /// Convert DTO to domain entity
  ServiceCategory toEntity() {
    return ServiceCategory(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      displayOrder: displayOrder,
      serviceCount: serviceCount,
    );
  }
}

/// Categories response DTO
@JsonSerializable()
class CategoriesResponseDto {
  const CategoriesResponseDto({required this.categories, required this.total});

  final List<ServiceCategoryDto> categories;
  final int total;

  factory CategoriesResponseDto.fromJson(Map<String, dynamic> json) => _$CategoriesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriesResponseDtoToJson(this);

  /// Convert DTO to domain entity
  CategoriesResponse toEntity() {
    return CategoriesResponse(categories: categories.map((dto) => dto.toEntity()).toList(), total: total);
  }
}
