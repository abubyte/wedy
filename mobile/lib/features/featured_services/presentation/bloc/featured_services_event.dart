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

/// Refresh featured services
final class RefreshFeaturedServicesEvent extends FeaturedServicesEvent {
  const RefreshFeaturedServicesEvent();
}
