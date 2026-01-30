// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_service_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedServiceDto _$FeaturedServiceDtoFromJson(Map<String, dynamic> json) =>
    FeaturedServiceDto(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      serviceName: json['service_name'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      daysDuration: (json['days_duration'] as num).toInt(),
      amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      featureType: json['feature_type'] as String,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
      viewsGained: (json['views_gained'] as num).toInt(),
      likesGained: (json['likes_gained'] as num).toInt(),
    );

Map<String, dynamic> _$FeaturedServiceDtoToJson(FeaturedServiceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_id': instance.serviceId,
      'service_name': instance.serviceName,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'days_duration': instance.daysDuration,
      'amount_paid': instance.amountPaid,
      'feature_type': instance.featureType,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'views_gained': instance.viewsGained,
      'likes_gained': instance.likesGained,
    };

MerchantFeaturedServicesDto _$MerchantFeaturedServicesDtoFromJson(
        Map<String, dynamic> json) =>
    MerchantFeaturedServicesDto(
      featuredServices: (json['featured_services'] as List<dynamic>)
          .map((e) => FeaturedServiceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      activeCount: (json['active_count'] as num).toInt(),
      remainingFreeSlots: (json['remaining_free_slots'] as num).toInt(),
    );

Map<String, dynamic> _$MerchantFeaturedServicesDtoToJson(
        MerchantFeaturedServicesDto instance) =>
    <String, dynamic>{
      'featured_services': instance.featuredServices,
      'total': instance.total,
      'active_count': instance.activeCount,
      'remaining_free_slots': instance.remainingFreeSlots,
    };
