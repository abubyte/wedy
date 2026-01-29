/// Featured services events using Dart 3 sealed classes for exhaustiveness checking
sealed class FeaturedServicesEvent {
  const FeaturedServicesEvent();
}

/// Load featured services tracking
final class LoadFeaturedServicesEvent extends FeaturedServicesEvent {
  const LoadFeaturedServicesEvent();
}

/// Create monthly featured service
final class CreateMonthlyFeaturedServiceEvent extends FeaturedServicesEvent {
  final String serviceId;

  const CreateMonthlyFeaturedServiceEvent(this.serviceId);
}

/// Create paid featured service payment
final class CreatePaidFeaturedServiceEvent extends FeaturedServicesEvent {
  final String serviceId;
  final int durationDays;
  final String paymentMethod;

  const CreatePaidFeaturedServiceEvent({
    required this.serviceId,
    required this.durationDays,
    required this.paymentMethod,
  });
}

/// Refresh featured services
final class RefreshFeaturedServicesEvent extends FeaturedServicesEvent {
  const RefreshFeaturedServicesEvent();
}
