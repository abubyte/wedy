/// Featured service entity (domain layer)
class FeaturedService {
  final String id;
  final String serviceId;
  final String serviceName;
  final DateTime startDate;
  final DateTime endDate;
  final int daysDuration;
  final double? amountPaid;
  final String featureType;
  final bool isActive;
  final DateTime createdAt;
  final int viewsGained;
  final int likesGained;

  const FeaturedService({
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

  bool get isFreeAllocation => featureType == 'monthly_allocation';
  bool get isPaidFeature => featureType == 'paid_feature';
}

/// Merchant featured services tracking response
class MerchantFeaturedServicesInfo {
  final List<FeaturedService> featuredServices;
  final int total;
  final int activeCount;
  final int remainingFreeSlots;

  const MerchantFeaturedServicesInfo({
    required this.featuredServices,
    required this.total,
    required this.activeCount,
    required this.remainingFreeSlots,
  });
}
