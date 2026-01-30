import 'package:equatable/equatable.dart';
import 'package:wedy/features/service/domain/entities/service.dart';

enum StateStatus { initial, loading, loaded, error, empty }

class FeaturedServicesState extends Equatable {
  final StateStatus status;
  final String? message;
  final List<ServiceListItem> data;

  const FeaturedServicesState({required this.status, required this.message, required this.data});

  factory FeaturedServicesState.empty() =>
      const FeaturedServicesState(status: StateStatus.initial, message: '', data: []);

  FeaturedServicesState copyWith({StateStatus? status, String? message, List<ServiceListItem>? data}) =>
      FeaturedServicesState(status: status ?? this.status, message: message ?? this.message, data: data ?? this.data);

  @override
  List<Object?> get props => [status, message, data];
}
