import 'package:equatable/equatable.dart';

/// Events for merchant service management
abstract class MerchantServiceEvent extends Equatable {
  const MerchantServiceEvent();

  @override
  List<Object?> get props => [];
}

/// Load merchant's services
class LoadMerchantServicesEvent extends MerchantServiceEvent {
  const LoadMerchantServicesEvent();
}

/// Create a new service
class CreateServiceEvent extends MerchantServiceEvent {
  final String name;
  final String description;
  final int categoryId;
  final double price;
  final String locationRegion;
  final double? latitude;
  final double? longitude;

  const CreateServiceEvent({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.locationRegion,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [name, description, categoryId, price, locationRegion, latitude, longitude];
}

/// Update a service
class UpdateServiceEvent extends MerchantServiceEvent {
  final String serviceId;
  final String? name;
  final String? description;
  final int? categoryId;
  final double? price;
  final String? locationRegion;
  final double? latitude;
  final double? longitude;

  const UpdateServiceEvent({
    required this.serviceId,
    this.name,
    this.description,
    this.categoryId,
    this.price,
    this.locationRegion,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [serviceId, name, description, categoryId, price, locationRegion, latitude, longitude];
}

/// Delete a service
class DeleteServiceEvent extends MerchantServiceEvent {
  final String serviceId;

  const DeleteServiceEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

/// Refresh merchant services
class RefreshMerchantServicesEvent extends MerchantServiceEvent {
  const RefreshMerchantServicesEvent();
}
