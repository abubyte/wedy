import 'package:equatable/equatable.dart';

/// Service category entity
class ServiceCategory extends Equatable {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.displayOrder,
    this.serviceCount = 0,
  });

  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int displayOrder;
  final int serviceCount;

  @override
  List<Object?> get props => [id, name, description, iconUrl, displayOrder, serviceCount];
}

/// Response containing list of categories
class CategoriesResponse extends Equatable {
  const CategoriesResponse({required this.categories, required this.total});

  final List<ServiceCategory> categories;
  final int total;

  @override
  List<Object?> get props => [categories, total];
}
