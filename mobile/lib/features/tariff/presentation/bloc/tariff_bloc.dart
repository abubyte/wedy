import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/create_tariff_payment.dart';
import '../../domain/usecases/get_subscription.dart';
import '../../domain/usecases/get_tariff_plans.dart';
import 'tariff_event.dart';
import 'tariff_state.dart';

/// BLoC for managing tariff plans and subscriptions
class TariffBloc extends Bloc<TariffEvent, TariffState> {
  final GetTariffPlans getTariffPlans;
  final GetSubscription getSubscription;
  final CreateTariffPayment createTariffPayment;

  TariffBloc({required this.getTariffPlans, required this.getSubscription, required this.createTariffPayment})
    : super(const TariffInitial()) {
    on<LoadTariffPlansEvent>(_onLoadTariffPlans);
    on<LoadSubscriptionEvent>(_onLoadSubscription);
    on<CreateTariffPaymentEvent>(_onCreateTariffPayment);
    on<RefreshTariffEvent>(_onRefreshTariff);
  }

  Future<void> _onLoadTariffPlans(LoadTariffPlansEvent event, Emitter<TariffState> emit) async {
    // Don't emit loading if we're already in a loaded state
    if (state is! TariffPlansLoaded && state is! TariffDataLoaded) {
      emit(const TariffLoading());
    }
    final result = await getTariffPlans();
    result.fold((failure) => emit(TariffError(_mapFailureToMessage(failure))), (plans) {
      // If subscription is already loaded, emit combined state
      if (state is SubscriptionLoaded) {
        final subState = state as SubscriptionLoaded;
        emit(TariffDataLoaded(plans: plans, subscription: subState.subscription));
      } else {
        emit(TariffPlansLoaded(plans));
      }
    });
  }

  Future<void> _onLoadSubscription(LoadSubscriptionEvent event, Emitter<TariffState> emit) async {
    // Don't emit loading if we're already in a loaded state
    if (state is! SubscriptionLoaded && state is! TariffDataLoaded) {
      emit(const TariffLoading());
    }
    final result = await getSubscription();
    result.fold((failure) => emit(TariffError(_mapFailureToMessage(failure))), (subscription) {
      // If plans are already loaded, emit combined state
      if (state is TariffPlansLoaded) {
        final plansState = state as TariffPlansLoaded;
        emit(TariffDataLoaded(plans: plansState.plans, subscription: subscription));
      } else {
        emit(SubscriptionLoaded(subscription));
      }
    });
  }

  Future<void> _onCreateTariffPayment(CreateTariffPaymentEvent event, Emitter<TariffState> emit) async {
    emit(const TariffLoading());
    final result = await createTariffPayment(
      tariffPlanId: event.tariffPlanId,
      durationMonths: event.durationMonths,
      paymentMethod: event.paymentMethod,
    );
    result.fold(
      (failure) => emit(TariffError(_mapFailureToMessage(failure))),
      (payment) => emit(PaymentCreated(payment)),
    );
  }

  Future<void> _onRefreshTariff(RefreshTariffEvent event, Emitter<TariffState> emit) async {
    add(const LoadTariffPlansEvent());
    add(const LoadSubscriptionEvent());
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
