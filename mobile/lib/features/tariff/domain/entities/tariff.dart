/// Tariff plan entity (domain layer)
class TariffPlan {
  final String id;
  final String name;
  final double pricePerMonth;
  final int maxServices;
  final int maxImagesPerService;
  final int maxPhoneNumbers;
  final int maxGalleryImages;
  final int maxSocialAccounts;
  final bool allowWebsite;
  final bool allowCoverImage;
  final int monthlyFeaturedCards;
  final bool isActive;
  final DateTime createdAt;

  TariffPlan({
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
}

/// Subscription entity (domain layer)
class Subscription {
  final String id;
  final TariffPlan tariffPlan;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.tariffPlan,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final end = endDate;
    if (end.isBefore(now)) return 0;
    return end.difference(now).inDays;
  }

  bool get isActive => status == SubscriptionStatus.active && daysRemaining > 0;
  bool get isExpired => status == SubscriptionStatus.expired || daysRemaining <= 0;
}

/// Subscription status enum
enum SubscriptionStatus { active, expired, cancelled }
