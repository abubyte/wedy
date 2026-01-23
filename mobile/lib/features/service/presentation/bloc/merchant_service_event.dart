/// Merchant service events using Dart 3 sealed classes for exhaustiveness checking
sealed class MerchantServiceEvent {
  const MerchantServiceEvent();
}

/// Load merchant's services
final class LoadMerchantServicesEvent extends MerchantServiceEvent {
  const LoadMerchantServicesEvent();
}

/// Create a new service
final class CreateServiceEvent extends MerchantServiceEvent {
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
}

/// Update a service
final class UpdateServiceEvent extends MerchantServiceEvent {
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
}

/// Delete a service
final class DeleteServiceEvent extends MerchantServiceEvent {
  final String serviceId;

  const DeleteServiceEvent(this.serviceId);
}

/// Refresh merchant services
final class RefreshMerchantServicesEvent extends MerchantServiceEvent {
  const RefreshMerchantServicesEvent();
}
