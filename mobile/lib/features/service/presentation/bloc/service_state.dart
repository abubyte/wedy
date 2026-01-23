import '../../domain/entities/service.dart';

/// Service states using Dart 3 sealed classes for exhaustiveness checking
sealed class ServiceState {
  const ServiceState();
}

/// Initial state
final class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

/// Loading state
final class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

/// Unified services state that holds all service data in a single immutable structure.
/// This follows BLoC best practices by keeping all related state together
/// and providing a copyWith method for immutable updates.
final class ServicesLoaded extends ServiceState {
  /// Featured services displayed on home page
  final List<ServiceListItem>? featuredServices;

  /// Services grouped by category (key: categoryId)
  final Map<int, List<ServiceListItem>> categoryServices;

  /// User's liked services
  final List<ServiceListItem>? likedServices;

  /// User's saved services
  final List<ServiceListItem>? savedServices;

  /// Current service details being viewed
  final Service? currentServiceDetails;

  /// Current paginated response for items/search pages
  final PaginatedServiceResponse? currentPaginatedResponse;

  /// Accumulated paginated services for infinite scroll
  final List<ServiceListItem>? paginatedServices;

  /// Pagination metadata
  final int currentPage;
  final bool hasMore;

  const ServicesLoaded({
    this.featuredServices,
    this.categoryServices = const {},
    this.likedServices,
    this.savedServices,
    this.currentServiceDetails,
    this.currentPaginatedResponse,
    this.paginatedServices,
    this.currentPage = 1,
    this.hasMore = true,
  });

  ServicesLoaded copyWith({
    List<ServiceListItem>? Function()? featuredServices,
    Map<int, List<ServiceListItem>>? categoryServices,
    List<ServiceListItem>? Function()? likedServices,
    List<ServiceListItem>? Function()? savedServices,
    Service? Function()? currentServiceDetails,
    PaginatedServiceResponse? Function()? currentPaginatedResponse,
    List<ServiceListItem>? Function()? paginatedServices,
    int? currentPage,
    bool? hasMore,
  }) {
    return ServicesLoaded(
      featuredServices: featuredServices != null ? featuredServices() : this.featuredServices,
      categoryServices: categoryServices ?? this.categoryServices,
      likedServices: likedServices != null ? likedServices() : this.likedServices,
      savedServices: savedServices != null ? savedServices() : this.savedServices,
      currentServiceDetails: currentServiceDetails != null ? currentServiceDetails() : this.currentServiceDetails,
      currentPaginatedResponse:
          currentPaginatedResponse != null ? currentPaginatedResponse() : this.currentPaginatedResponse,
      paginatedServices: paginatedServices != null ? paginatedServices() : this.paginatedServices,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Helper to update a specific service in all lists
  ServicesLoaded updateService(String serviceId, ServiceListItem Function(ServiceListItem) updater) {
    return copyWith(
      featuredServices: () => featuredServices?.map((s) => s.id == serviceId ? updater(s) : s).toList(),
      categoryServices: categoryServices.map(
        (categoryId, services) =>
            MapEntry(categoryId, services.map((s) => s.id == serviceId ? updater(s) : s).toList()),
      ),
      likedServices: () => likedServices?.map((s) => s.id == serviceId ? updater(s) : s).toList(),
      savedServices: () => savedServices?.map((s) => s.id == serviceId ? updater(s) : s).toList(),
      paginatedServices: () => paginatedServices?.map((s) => s.id == serviceId ? updater(s) : s).toList(),
    );
  }
}

/// Error state
final class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);
}
