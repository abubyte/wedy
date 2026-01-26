import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/features/service/domain/usecases/get_featured_services.dart';
import 'package:wedy/apps/client/pages/home/blocs/featured_services/featured_services_event.dart';
import 'package:wedy/apps/client/pages/home/blocs/featured_services/featured_services_state.dart';

class FeaturedServicesBloc
    extends Bloc<FeaturedServicesEvent, FeaturedServicesState> {
  final GetFeaturedServices _getFeaturedServicesUseCase;

  FeaturedServicesBloc({
    required GetFeaturedServices getFeaturedServicesUseCase,
  }) : _getFeaturedServicesUseCase = getFeaturedServicesUseCase,
       super(FeaturedServicesState.empty()) {
    on<FetchFeaturedServices>(_fetchFeaturedServices);
  }

  Future<void> _fetchFeaturedServices(
    FetchFeaturedServices event,
    Emitter<FeaturedServicesState> emit,
  ) async {
    emit(state.copyWith(status: StateStatus.loading));

    final result = await _getFeaturedServicesUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StateStatus.error,
          message: "Qaynoq takliflarni yuklab bo'lmadi",
        ),
      ),
      (response) => emit(
        state.copyWith(
          status: StateStatus.loaded,
          message: 'Qaynoq takliflar muvoffaqiyatli yuklandi',
          data: response.services,
        ),
      ),
    );
  }
}
