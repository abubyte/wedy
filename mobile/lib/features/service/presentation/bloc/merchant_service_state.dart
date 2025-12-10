import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

/// States for merchant service management
abstract class MerchantServiceState extends Equatable {
  const MerchantServiceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MerchantServiceInitial extends MerchantServiceState {
  const MerchantServiceInitial();
}

/// Loading state
class MerchantServiceLoading extends MerchantServiceState {
  const MerchantServiceLoading();
}

/// Services loaded successfully (for backward compatibility)
class MerchantServicesLoaded extends MerchantServiceState {
  final MerchantServicesResponse servicesResponse;

  const MerchantServicesLoaded(this.servicesResponse);

  @override
  List<Object?> get props => [servicesResponse];
}

/// Single merchant service loaded successfully (nullable - null means no service)
class MerchantServiceLoaded extends MerchantServiceState {
  final MerchantService? service;

  const MerchantServiceLoaded(this.service);

  @override
  List<Object?> get props => [service];
}

/// Service created successfully
class ServiceCreated extends MerchantServiceState {
  final Service service;

  const ServiceCreated(this.service);

  @override
  List<Object?> get props => [service];
}

/// Service updated successfully
class ServiceUpdated extends MerchantServiceState {
  final Service service;

  const ServiceUpdated(this.service);

  @override
  List<Object?> get props => [service];
}

/// Service deleted successfully
class ServiceDeleted extends MerchantServiceState {
  final String serviceId;

  const ServiceDeleted(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

/// Error state
class MerchantServiceError extends MerchantServiceState {
  final String message;

  const MerchantServiceError(this.message);

  @override
  List<Object?> get props => [message];
}
