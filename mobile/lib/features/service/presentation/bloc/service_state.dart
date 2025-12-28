import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

/// Service states
abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

/// Loading state
class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

/// Universal services state - holds all service types simultaneously
class UniversalServicesState extends ServiceState {
  // Featured services
  final List<ServiceListItem>? featuredServices;

  // Services by category (key: categoryId, value: list of services)
  final Map<int, List<ServiceListItem>> categoryServices;

  // Liked services
  final List<ServiceListItem>? likedServices;

  // Saved services
  final List<ServiceListItem>? savedServices;

  // Current service details being viewed
  final Service? currentServiceDetails;

  // Current paginated services (for items/search pages)
  final PaginatedServiceResponse? currentPaginatedResponse;
  final List<ServiceListItem>? currentPaginatedServices;

  const UniversalServicesState({
    this.featuredServices,
    this.categoryServices = const {},
    this.likedServices,
    this.savedServices,
    this.currentServiceDetails,
    this.currentPaginatedResponse,
    this.currentPaginatedServices,
  });

  UniversalServicesState copyWith({
    List<ServiceListItem>? featuredServices,
    Map<int, List<ServiceListItem>>? categoryServices,
    List<ServiceListItem>? Function()? likedServices,
    List<ServiceListItem>? Function()? savedServices,
    Service? Function()? currentServiceDetails,
    PaginatedServiceResponse? Function()? currentPaginatedResponse,
    List<ServiceListItem>? Function()? currentPaginatedServices,
    bool clearFeaturedServices = false,
    bool clearLikedServices = false,
    bool clearSavedServices = false,
    bool clearCurrentServiceDetails = false,
    bool clearCurrentPaginated = false,
  }) {
    return UniversalServicesState(
      featuredServices: clearFeaturedServices ? null : (featuredServices ?? this.featuredServices),
      categoryServices: categoryServices ?? this.categoryServices,
      likedServices: clearLikedServices ? null : (likedServices != null ? likedServices() : this.likedServices),
      savedServices: clearSavedServices ? null : (savedServices != null ? savedServices() : this.savedServices),
      currentServiceDetails: clearCurrentServiceDetails
          ? null
          : (currentServiceDetails != null ? currentServiceDetails() : this.currentServiceDetails),
      currentPaginatedResponse: clearCurrentPaginated
          ? null
          : (currentPaginatedResponse != null ? currentPaginatedResponse() : this.currentPaginatedResponse),
      currentPaginatedServices: clearCurrentPaginated
          ? null
          : (currentPaginatedServices != null ? currentPaginatedServices() : this.currentPaginatedServices),
    );
  }

  @override
  List<Object?> get props => [
    featuredServices,
    categoryServices,
    likedServices,
    savedServices,
    currentServiceDetails,
    currentPaginatedResponse,
    currentPaginatedServices,
  ];
}

/// Services loaded state (kept for backward compatibility during migration)
class ServicesLoaded extends ServiceState {
  final PaginatedServiceResponse response;
  final List<ServiceListItem> allServices; // Accumulated list for pagination

  const ServicesLoaded({required this.response, required this.allServices});

  @override
  List<Object?> get props => [response, allServices];
}

/// Service details loaded state
class ServiceDetailsLoaded extends ServiceState {
  final Service service;

  const ServiceDetailsLoaded(this.service);

  @override
  List<Object?> get props => [service];
}

/// Service interaction success state
class ServiceInteractionSuccess extends ServiceState {
  final String message;
  final int newCount;
  final String interactionType;
  final bool isActive;

  const ServiceInteractionSuccess({
    required this.message,
    required this.newCount,
    required this.interactionType,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [message, newCount, interactionType, isActive];
}

/// Saved services loaded state
class SavedServicesLoaded extends ServiceState {
  final List<ServiceListItem> savedServices;

  const SavedServicesLoaded(this.savedServices);

  @override
  List<Object?> get props => [savedServices];
}

/// Liked services loaded state
class LikedServicesLoaded extends ServiceState {
  final List<ServiceListItem> likedServices;

  const LikedServicesLoaded(this.likedServices);

  @override
  List<Object?> get props => [likedServices];
}

/// Error state
class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}
