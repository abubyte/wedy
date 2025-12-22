import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/get_service_by_id.dart';
import '../../domain/usecases/interact_with_service.dart';
import '../../domain/usecases/get_saved_services.dart';
import '../../domain/entities/service.dart';
import 'service_event.dart';
import 'service_state.dart';

/// Service BLoC for managing service state
class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final GetServices getServicesUseCase;
  final GetServiceById getServiceByIdUseCase;
  final InteractWithService interactWithServiceUseCase;
  final GetSavedServices getSavedServicesUseCase;

  // Store accumulated services for pagination
  List<ServiceListItem> _accumulatedServices = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool? _currentFeatured;
  ServiceSearchFilters? _currentFilters;

  ServiceBloc({
    required this.getServicesUseCase,
    required this.getServiceByIdUseCase,
    required this.interactWithServiceUseCase,
    required this.getSavedServicesUseCase,
  }) : super(const ServiceInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<LoadMoreServicesEvent>(_onLoadMoreServices);
    on<LoadServiceByIdEvent>(_onLoadServiceById);
    on<InteractWithServiceEvent>(_onInteractWithService);
    on<RefreshServicesEvent>(_onRefreshServices);
    on<LoadSavedServicesEvent>(_onLoadSavedServices);
  }

  Future<void> _onLoadServices(LoadServicesEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    // Reset accumulated services for new load
    _accumulatedServices = [];
    _currentPage = 1;
    _hasMore = true;
    _currentFeatured = event.featured;
    _currentFilters = event.filters;

    final result = await getServicesUseCase(
      featured: event.featured,
      filters: event.filters,
      page: event.page,
      limit: event.limit,
    );

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (response) {
      _accumulatedServices = List.from(response.services);
      _currentPage = response.page;
      _hasMore = response.hasMore;
      emit(ServicesLoaded(response: response, allServices: _accumulatedServices));
    });
  }

  Future<void> _onLoadMoreServices(LoadMoreServicesEvent event, Emitter<ServiceState> emit) async {
    if (!_hasMore || state is ServiceLoading) return;

    final nextPage = _currentPage + 1;

    final result = await getServicesUseCase(
      featured: _currentFeatured,
      filters: _currentFilters,
      page: nextPage,
      limit: 20,
    );

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (response) {
      _accumulatedServices.addAll(response.services);
      _currentPage = response.page;
      _hasMore = response.hasMore;
      emit(ServicesLoaded(response: response, allServices: _accumulatedServices));
    });
  }

  Future<void> _onLoadServiceById(LoadServiceByIdEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    final result = await getServiceByIdUseCase(event.serviceId);

    result.fold(
      (failure) => emit(ServiceError(_getErrorMessage(failure))),
      (service) => emit(ServiceDetailsLoaded(service)),
    );
  }

  Future<void> _onInteractWithService(InteractWithServiceEvent event, Emitter<ServiceState> emit) async {
    final result = await interactWithServiceUseCase(event.serviceId, event.interactionType);

    result.fold(
      (failure) => emit(ServiceError(_getErrorMessage(failure))),
      (response) => emit(
        ServiceInteractionSuccess(
          message: response.message,
          newCount: response.newCount,
          interactionType: event.interactionType,
          isActive: response.isActive,
        ),
      ),
    );
  }

  Future<void> _onRefreshServices(RefreshServicesEvent event, Emitter<ServiceState> emit) async {
    // Reset and reload
    add(
      LoadServicesEvent(
        featured: event.featured ?? _currentFeatured,
        filters: event.filters ?? _currentFilters,
        page: 1,
        limit: 20,
      ),
    );
  }

  Future<void> _onLoadSavedServices(LoadSavedServicesEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    final result = await getSavedServicesUseCase();

    result.fold(
      (failure) => emit(ServiceError(_getErrorMessage(failure))),
      (savedServices) => emit(SavedServicesLoaded(savedServices)),
    );
  }

  String _getErrorMessage(dynamic failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your internet connection.';
    } else if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is NotFoundFailure) {
      return 'Service not found.';
    } else if (failure is AuthFailure) {
      return 'Authentication failed. Please login again.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred.';
  }
}
