// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tariff_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TariffPlanDto _$TariffPlanDtoFromJson(Map<String, dynamic> json) =>
    TariffPlanDto(
      id: json['id'] as String,
      name: json['name'] as String,
      pricePerMonth: (json['price_per_month'] as num).toDouble(),
      maxServices: (json['max_services'] as num).toInt(),
      maxImagesPerService: (json['max_images_per_service'] as num).toInt(),
      maxPhoneNumbers: (json['max_phone_numbers'] as num).toInt(),
      maxGalleryImages: (json['max_gallery_images'] as num).toInt(),
      maxSocialAccounts: (json['max_social_accounts'] as num).toInt(),
      allowWebsite: json['allow_website'] as bool,
      allowCoverImage: json['allow_cover_image'] as bool,
      monthlyFeaturedCards: (json['monthly_featured_cards'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$TariffPlanDtoToJson(TariffPlanDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_per_month': instance.pricePerMonth,
      'max_services': instance.maxServices,
      'max_images_per_service': instance.maxImagesPerService,
      'max_phone_numbers': instance.maxPhoneNumbers,
      'max_gallery_images': instance.maxGalleryImages,
      'max_social_accounts': instance.maxSocialAccounts,
      'allow_website': instance.allowWebsite,
      'allow_cover_image': instance.allowCoverImage,
      'monthly_featured_cards': instance.monthlyFeaturedCards,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };

SubscriptionDto _$SubscriptionDtoFromJson(Map<String, dynamic> json) =>
    SubscriptionDto(
      id: json['id'] as String,
      tariffPlan:
          TariffPlanDto.fromJson(json['tariff_plan'] as Map<String, dynamic>),
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$SubscriptionDtoToJson(SubscriptionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tariff_plan': instance.tariffPlan,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'status': instance.status,
      'created_at': instance.createdAt,
    };

SubscriptionWithLimitsResponseDto _$SubscriptionWithLimitsResponseDtoFromJson(
        Map<String, dynamic> json) =>
    SubscriptionWithLimitsResponseDto(
      subscription: json['subscription'] == null
          ? null
          : SubscriptionDto.fromJson(
              json['subscription'] as Map<String, dynamic>),
      limits: json['limits'] as Map<String, dynamic>?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$SubscriptionWithLimitsResponseDtoToJson(
        SubscriptionWithLimitsResponseDto instance) =>
    <String, dynamic>{
      'subscription': instance.subscription,
      'limits': instance.limits,
      'message': instance.message,
    };

PaymentResponseDto _$PaymentResponseDtoFromJson(Map<String, dynamic> json) =>
    PaymentResponseDto(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentType: json['payment_type'] as String,
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      paymentUrl: json['payment_url'] as String?,
      transactionId: json['transaction_id'] as String?,
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
    );

Map<String, dynamic> _$PaymentResponseDtoToJson(PaymentResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'payment_type': instance.paymentType,
      'payment_method': instance.paymentMethod,
      'status': instance.status,
      'payment_url': instance.paymentUrl,
      'transaction_id': instance.transactionId,
      'created_at': instance.createdAt,
      'completed_at': instance.completedAt,
    };
