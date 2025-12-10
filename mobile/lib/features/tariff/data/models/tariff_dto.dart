import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/tariff.dart';

part 'tariff_dto.g.dart';

/// Tariff plan DTO
@JsonSerializable()
class TariffPlanDto {
  final String id;
  final String name;
  @JsonKey(name: 'price_per_month')
  final double pricePerMonth;
  @JsonKey(name: 'max_services')
  final int maxServices;
  @JsonKey(name: 'max_images_per_service')
  final int maxImagesPerService;
  @JsonKey(name: 'max_phone_numbers')
  final int maxPhoneNumbers;
  @JsonKey(name: 'max_gallery_images')
  final int maxGalleryImages;
  @JsonKey(name: 'max_social_accounts')
  final int maxSocialAccounts;
  @JsonKey(name: 'allow_website')
  final bool allowWebsite;
  @JsonKey(name: 'allow_cover_image')
  final bool allowCoverImage;
  @JsonKey(name: 'monthly_featured_cards')
  final int monthlyFeaturedCards;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;

  TariffPlanDto({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.maxServices,
    required this.maxImagesPerService,
    required this.maxPhoneNumbers,
    required this.maxGalleryImages,
    required this.maxSocialAccounts,
    required this.allowWebsite,
    required this.allowCoverImage,
    required this.monthlyFeaturedCards,
    required this.isActive,
    required this.createdAt,
  });

  factory TariffPlanDto.fromJson(Map<String, dynamic> json) => _$TariffPlanDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TariffPlanDtoToJson(this);

  TariffPlan toEntity() {
    return TariffPlan(
      id: id,
      name: name,
      pricePerMonth: pricePerMonth,
      maxServices: maxServices,
      maxImagesPerService: maxImagesPerService,
      maxPhoneNumbers: maxPhoneNumbers,
      maxGalleryImages: maxGalleryImages,
      maxSocialAccounts: maxSocialAccounts,
      allowWebsite: allowWebsite,
      allowCoverImage: allowCoverImage,
      monthlyFeaturedCards: monthlyFeaturedCards,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

/// Subscription DTO
@JsonSerializable()
class SubscriptionDto {
  final String id;
  @JsonKey(name: 'tariff_plan')
  final TariffPlanDto tariffPlan;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  SubscriptionDto({
    required this.id,
    required this.tariffPlan,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) => _$SubscriptionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionDtoToJson(this);

  Subscription toEntity() {
    // Parse dates - backend returns date objects as "YYYY-MM-DD" format
    // DateTime.parse can handle this, but we need to ensure it's treated as UTC
    DateTime parseDate(String dateStr) {
      // If it's just a date (YYYY-MM-DD), add time component
      if (dateStr.length == 10) {
        return DateTime.parse('${dateStr}T00:00:00Z').toLocal();
      }
      return DateTime.parse(dateStr).toLocal();
    }

    return Subscription(
      id: id,
      tariffPlan: tariffPlan.toEntity(),
      startDate: parseDate(startDate),
      endDate: parseDate(endDate),
      status: _parseStatus(status),
      createdAt: DateTime.parse(createdAt).toLocal(),
    );
  }

  SubscriptionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.expired;
    }
  }
}

/// Subscription with limits response DTO
@JsonSerializable()
class SubscriptionWithLimitsResponseDto {
  final SubscriptionDto? subscription;
  final Map<String, dynamic>? limits;
  final String? message;

  SubscriptionWithLimitsResponseDto({this.subscription, this.limits, this.message});

  factory SubscriptionWithLimitsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionWithLimitsResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionWithLimitsResponseDtoToJson(this);
}

/// Payment response DTO
@JsonSerializable()
class PaymentResponseDto {
  final String id;
  final double amount;
  @JsonKey(name: 'payment_type')
  final String paymentType;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  final String status;
  @JsonKey(name: 'payment_url')
  final String? paymentUrl;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;

  PaymentResponseDto({
    required this.id,
    required this.amount,
    required this.paymentType,
    required this.paymentMethod,
    required this.status,
    this.paymentUrl,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) => _$PaymentResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentResponseDtoToJson(this);
}
