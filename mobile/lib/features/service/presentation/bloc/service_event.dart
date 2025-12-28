import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

/// Service events
abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

/// Load services event
class LoadServicesEvent extends ServiceEvent {
  final bool? featured;
  final ServiceSearchFilters? filters;
  final int page;
  final int limit;

  const LoadServicesEvent({this.featured, this.filters, this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [featured, filters, page, limit];
}

/// Load more services event (pagination)
class LoadMoreServicesEvent extends ServiceEvent {
  const LoadMoreServicesEvent();
}

/// Load service details by ID
class LoadServiceByIdEvent extends ServiceEvent {
  final String serviceId;

  const LoadServiceByIdEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

/// Interact with service (like, save, share)
class InteractWithServiceEvent extends ServiceEvent {
  final String serviceId;
  final String interactionType; // 'like', 'save', 'share'

  const InteractWithServiceEvent({required this.serviceId, required this.interactionType});

  @override
  List<Object?> get props => [serviceId, interactionType];
}

/// Refresh services event
class RefreshServicesEvent extends ServiceEvent {
  final bool? featured;
  final ServiceSearchFilters? filters;

  const RefreshServicesEvent({this.featured, this.filters});

  @override
  List<Object?> get props => [featured, filters];
}

/// Load saved services event
class LoadSavedServicesEvent extends ServiceEvent {
  const LoadSavedServicesEvent();
}

/// Load liked services event
class LoadLikedServicesEvent extends ServiceEvent {
  const LoadLikedServicesEvent();
}

/// Restore last services state event (for when pages become visible)
class RestoreLastServicesStateEvent extends ServiceEvent {
  const RestoreLastServicesStateEvent();
}

/// Restore last liked services state event
class RestoreLastLikedServicesStateEvent extends ServiceEvent {
  const RestoreLastLikedServicesStateEvent();
}
