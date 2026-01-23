import '../../domain/entities/service.dart';

/// Service events using Dart 3 sealed classes for exhaustiveness checking
sealed class ServiceEvent {
  const ServiceEvent();
}

/// Load services event
final class LoadServicesEvent extends ServiceEvent {
  final bool? featured;
  final ServiceSearchFilters? filters;
  final int page;
  final int limit;

  const LoadServicesEvent({this.featured, this.filters, this.page = 1, this.limit = 20});
}

/// Load more services event (pagination)
final class LoadMoreServicesEvent extends ServiceEvent {
  const LoadMoreServicesEvent();
}

/// Load service details by ID
final class LoadServiceByIdEvent extends ServiceEvent {
  final String serviceId;

  const LoadServiceByIdEvent(this.serviceId);
}

/// Interact with service (like, save, share)
final class InteractWithServiceEvent extends ServiceEvent {
  final String serviceId;
  final String interactionType; // 'like', 'save', 'share'

  const InteractWithServiceEvent({required this.serviceId, required this.interactionType});
}

/// Refresh services event
final class RefreshServicesEvent extends ServiceEvent {
  final bool? featured;
  final ServiceSearchFilters? filters;

  const RefreshServicesEvent({this.featured, this.filters});
}

/// Load saved services event
final class LoadSavedServicesEvent extends ServiceEvent {
  const LoadSavedServicesEvent();
}

/// Load liked services event
final class LoadLikedServicesEvent extends ServiceEvent {
  const LoadLikedServicesEvent();
}
