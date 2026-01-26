import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/featured_service.dart';

part 'featured_service_dto.g.dart';

/// Featured service DTO
@JsonSerializable()
class FeaturedServiceDto {
  final String id;
  @JsonKey(name: 'service_id')
  final String serviceId;
  @JsonKey(name: 'service_name')
  final String serviceName;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'days_duration')
  final int daysDuration;
  @JsonKey(name: 'amount_paid')
  final double? amountPaid;
  @JsonKey(name: 'feature_type')
  final String featureType;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'views_gained')
  final int viewsGained;
  @JsonKey(name: 'likes_gained')
  final int likesGained;

  FeaturedServiceDto({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.startDate,
    required this.endDate,
    required this.daysDuration,
    this.amountPaid,
    required this.featureType,
    required this.isActive,
    required this.createdAt,
    required this.viewsGained,
    required this.likesGained,
  });

  factory FeaturedServiceDto.fromJson(Map<String, dynamic> json) =>
      _$FeaturedServiceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$FeaturedServiceDtoToJson(this);

  FeaturedService toEntity() {
    return FeaturedService(
      id: id,
      serviceId: serviceId,
      serviceName: serviceName,
      startDate: DateTime.parse(startDate),
      endDate: DateTime.parse(endDate),
      daysDuration: daysDuration,
      amountPaid: amountPaid,
      featureType: featureType,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
      viewsGained: viewsGained,
      likesGained: likesGained,
    );
  }
}

/// Merchant featured services response DTO
@JsonSerializable()
class MerchantFeaturedServicesDto {
  @JsonKey(name: 'featured_services')
  final List<FeaturedServiceDto> featuredServices;
  final int total;
  @JsonKey(name: 'active_count')
  final int activeCount;
  @JsonKey(name: 'remaining_free_slots')
  final int remainingFreeSlots;

  MerchantFeaturedServicesDto({
    required this.featuredServices,
    required this.total,
    required this.activeCount,
    required this.remainingFreeSlots,
  });

  factory MerchantFeaturedServicesDto.fromJson(Map<String, dynamic> json) =>
      _$MerchantFeaturedServicesDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantFeaturedServicesDtoToJson(this);

  MerchantFeaturedServicesInfo toEntity() {
    return MerchantFeaturedServicesInfo(
      featuredServices: featuredServices.map((f) => f.toEntity()).toList(),
      total: total,
      activeCount: activeCount,
      remainingFreeSlots: remainingFreeSlots,
    );
  }
}
