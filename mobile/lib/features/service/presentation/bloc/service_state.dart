import '../../domain/entities/service.dart';

/// Loading type enum for granular loading states
enum ServiceLoadingType {
  /// Loading service list (featured, category, search)
  list,

  /// Loading service details
  details,

  /// Loading more services (pagination)
  loadMore,

  /// Performing interaction (like/save)
  interaction,

  /// Loading saved/liked services
  userServices,
}

/// Error type enum for specific error handling
enum ServiceErrorType { network, server, validation, auth, notFound, unknown }

/// Service states using Dart 3 sealed classes for exhaustiveness checking
sealed class ServiceState {
  const ServiceState();
}

/// Initial state
final class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

/// Loading state with type information
final class ServiceLoading extends ServiceState {
  final ServiceLoadingType type;
  final ServicesLoaded? previousState;

  const ServiceLoading({this.type = ServiceLoadingType.list, this.previousState});
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

  /// Interaction tracking for optimistic UI
  final bool isInteracting;
  final String? interactingServiceId;
  final String? interactionType;

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
    this.isInteracting = false,
    this.interactingServiceId,
    this.interactionType,
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
    bool? isInteracting,
    String? Function()? interactingServiceId,
    String? Function()? interactionType,
  }) {
    return ServicesLoaded(
      featuredServices: featuredServices != null ? featuredServices() : this.featuredServices,
      categoryServices: categoryServices ?? this.categoryServices,
      likedServices: likedServices != null ? likedServices() : this.likedServices,
      savedServices: savedServices != null ? savedServices() : this.savedServices,
      currentServiceDetails: currentServiceDetails != null ? currentServiceDetails() : this.currentServiceDetails,
      currentPaginatedResponse: currentPaginatedResponse != null
          ? currentPaginatedResponse()
          : this.currentPaginatedResponse,
      paginatedServices: paginatedServices != null ? paginatedServices() : this.paginatedServices,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isInteracting: isInteracting ?? this.isInteracting,
      interactingServiceId: interactingServiceId != null ? interactingServiceId() : this.interactingServiceId,
      interactionType: interactionType != null ? interactionType() : this.interactionType,
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

  /// Clear interaction state
  ServicesLoaded clearInteraction() {
    return copyWith(isInteracting: false, interactingServiceId: () => null, interactionType: () => null);
  }
}

/// Error state with type information
final class ServiceError extends ServiceState {
  final String message;
  final ServiceErrorType type;
  final ServicesLoaded? previousState;

  const ServiceError(this.message, {this.type = ServiceErrorType.unknown, this.previousState});
}
