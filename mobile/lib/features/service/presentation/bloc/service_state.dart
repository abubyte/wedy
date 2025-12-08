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

/// Services loaded state
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

  const ServiceInteractionSuccess({required this.message, required this.newCount, required this.interactionType});

  @override
  List<Object?> get props => [message, newCount, interactionType];
}

/// Saved services loaded state
class SavedServicesLoaded extends ServiceState {
  final List<ServiceListItem> savedServices;

  const SavedServicesLoaded(this.savedServices);

  @override
  List<Object?> get props => [savedServices];
}

/// Error state
class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}
