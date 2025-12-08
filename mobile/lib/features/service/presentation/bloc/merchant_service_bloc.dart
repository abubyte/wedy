import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/create_merchant_service.dart';
import '../../domain/usecases/delete_merchant_service.dart';
import '../../domain/usecases/get_merchant_services.dart';
import '../../domain/usecases/update_merchant_service.dart';
import 'merchant_service_event.dart';
import 'merchant_service_state.dart';

/// BLoC for managing merchant services
class MerchantServiceBloc extends Bloc<MerchantServiceEvent, MerchantServiceState> {
  final GetMerchantServices getMerchantServices;
  final CreateMerchantService createMerchantService;
  final UpdateMerchantService updateMerchantService;
  final DeleteMerchantService deleteMerchantService;

  MerchantServiceBloc({
    required this.getMerchantServices,
    required this.createMerchantService,
    required this.updateMerchantService,
    required this.deleteMerchantService,
  }) : super(const MerchantServiceInitial()) {
    on<LoadMerchantServicesEvent>(_onLoadMerchantServices);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
    on<RefreshMerchantServicesEvent>(_onRefreshMerchantServices);
  }

  Future<void> _onLoadMerchantServices(LoadMerchantServicesEvent event, Emitter<MerchantServiceState> emit) async {
    emit(const MerchantServiceLoading());
    final result = await getMerchantServices();
    result.fold(
      (failure) => emit(MerchantServiceError(_mapFailureToMessage(failure))),
      (servicesResponse) => emit(MerchantServicesLoaded(servicesResponse)),
    );
  }

  Future<void> _onCreateService(CreateServiceEvent event, Emitter<MerchantServiceState> emit) async {
    emit(const MerchantServiceLoading());
    final result = await createMerchantService(
      name: event.name,
      description: event.description,
      categoryId: event.categoryId,
      price: event.price,
      locationRegion: event.locationRegion,
      latitude: event.latitude,
      longitude: event.longitude,
    );
    result.fold((failure) => emit(MerchantServiceError(_mapFailureToMessage(failure))), (service) {
      emit(ServiceCreated(service));
      // Reload services after creation
      add(const LoadMerchantServicesEvent());
    });
  }

  Future<void> _onUpdateService(UpdateServiceEvent event, Emitter<MerchantServiceState> emit) async {
    emit(const MerchantServiceLoading());
    final result = await updateMerchantService(
      serviceId: event.serviceId,
      name: event.name,
      description: event.description,
      categoryId: event.categoryId,
      price: event.price,
      locationRegion: event.locationRegion,
      latitude: event.latitude,
      longitude: event.longitude,
    );
    result.fold((failure) => emit(MerchantServiceError(_mapFailureToMessage(failure))), (service) {
      emit(ServiceUpdated(service));
      // Reload services after update
      add(const LoadMerchantServicesEvent());
    });
  }

  Future<void> _onDeleteService(DeleteServiceEvent event, Emitter<MerchantServiceState> emit) async {
    emit(const MerchantServiceLoading());
    final result = await deleteMerchantService(event.serviceId);
    result.fold((failure) => emit(MerchantServiceError(_mapFailureToMessage(failure))), (_) {
      emit(ServiceDeleted(event.serviceId));
      // Reload services after deletion
      add(const LoadMerchantServicesEvent());
    });
  }

  Future<void> _onRefreshMerchantServices(
    RefreshMerchantServicesEvent event,
    Emitter<MerchantServiceState> emit,
  ) async {
    add(const LoadMerchantServicesEvent());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (NetworkFailure):
        return (failure as NetworkFailure).message;
      case const (ServerFailure):
        return (failure as ServerFailure).message;
      case const (ValidationFailure):
        return (failure as ValidationFailure).message;
      case const (AuthFailure):
        return (failure as AuthFailure).message;
      case const (NotFoundFailure):
        return (failure as NotFoundFailure).message;
      default:
        return 'An unexpected error occurred';
    }
  }
}
