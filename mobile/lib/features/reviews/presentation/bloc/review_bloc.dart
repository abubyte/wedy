import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_reviews.dart';
import '../../domain/usecases/get_user_reviews.dart';
import '../../domain/usecases/create_review.dart';
import '../../domain/usecases/update_review.dart';
import '../../domain/usecases/delete_review.dart';
import 'review_event.dart';
import 'review_state.dart';

/// Review BLoC for managing review state
///
/// Pagination state is tracked in [ReviewsLoaded] state rather than
/// private mutable fields, following BLoC best practices.
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final GetReviews _getReviewsUseCase;
  final GetUserReviews _getUserReviewsUseCase;
  final CreateReview _createReviewUseCase;
  final UpdateReview _updateReviewUseCase;
  final DeleteReview _deleteReviewUseCase;

  // Track current context for pagination (service or user reviews)
  String? _currentServiceId;
  String? _currentUserId;

  ReviewBloc({
    required GetReviews getReviewsUseCase,
    required GetUserReviews getUserReviewsUseCase,
    required CreateReview createReviewUseCase,
    required UpdateReview updateReviewUseCase,
    required DeleteReview deleteReviewUseCase,
  })  : _getReviewsUseCase = getReviewsUseCase,
        _getUserReviewsUseCase = getUserReviewsUseCase,
        _createReviewUseCase = createReviewUseCase,
        _updateReviewUseCase = updateReviewUseCase,
        _deleteReviewUseCase = deleteReviewUseCase,
        super(const ReviewInitial()) {
    on<LoadReviewsEvent>(_onLoadReviews);
    on<LoadMoreReviewsEvent>(_onLoadMoreReviews);
    on<LoadUserReviewsEvent>(_onLoadUserReviews);
    on<LoadMoreUserReviewsEvent>(_onLoadMoreUserReviews);
    on<CreateReviewEvent>(_onCreateReview);
    on<UpdateReviewEvent>(_onUpdateReview);
    on<DeleteReviewEvent>(_onDeleteReview);
    on<RefreshReviewsEvent>(_onRefreshReviews);
  }

  /// Get current loaded state if available
  ReviewsLoaded? get _currentLoadedState => state is ReviewsLoaded ? state as ReviewsLoaded : null;

  Future<void> _onLoadReviews(LoadReviewsEvent event, Emitter<ReviewState> emit) async {
    emit(const ReviewLoading());

    _currentServiceId = event.serviceId;
    _currentUserId = null;

    final result = await _getReviewsUseCase(
      serviceId: event.serviceId,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Reviews'))),
      (response) => emit(ReviewsLoaded(
        response: response,
        allReviews: response.reviews,
        hasMore: response.hasMore,
      )),
    );
  }

  Future<void> _onLoadMoreReviews(LoadMoreReviewsEvent event, Emitter<ReviewState> emit) async {
    final currentState = _currentLoadedState;
    if (currentState == null || !currentState.hasMore || _currentServiceId == null) return;
    if (state is ReviewLoading) return;

    final nextPage = currentState.response.page + 1;

    final result = await _getReviewsUseCase(
      serviceId: _currentServiceId!,
      page: nextPage,
      limit: 20,
    );

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Reviews'))),
      (response) => emit(currentState.copyWith(
        response: response,
        allReviews: [...currentState.allReviews, ...response.reviews],
        hasMore: response.hasMore,
      )),
    );
  }

  Future<void> _onLoadUserReviews(LoadUserReviewsEvent event, Emitter<ReviewState> emit) async {
    emit(const ReviewLoading());

    _currentUserId = event.userId;
    _currentServiceId = null;

    final result = await _getUserReviewsUseCase(
      userId: event.userId,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Reviews'))),
      (response) => emit(ReviewsLoaded(
        response: response,
        allReviews: response.reviews,
        hasMore: response.hasMore,
      )),
    );
  }

  Future<void> _onLoadMoreUserReviews(LoadMoreUserReviewsEvent event, Emitter<ReviewState> emit) async {
    final currentState = _currentLoadedState;
    if (currentState == null || !currentState.hasMore || _currentUserId == null) return;
    if (state is ReviewLoading) return;

    final nextPage = currentState.response.page + 1;

    final result = await _getUserReviewsUseCase(
      userId: _currentUserId!,
      page: nextPage,
      limit: 20,
    );

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Reviews'))),
      (response) => emit(currentState.copyWith(
        response: response,
        allReviews: [...currentState.allReviews, ...response.reviews],
        hasMore: response.hasMore,
      )),
    );
  }

  Future<void> _onCreateReview(CreateReviewEvent event, Emitter<ReviewState> emit) async {
    final result = await _createReviewUseCase(
      serviceId: event.serviceId,
      rating: event.rating,
      comment: event.comment,
    );

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Review'))),
      (review) {
        emit(ReviewCreated(review));
        // Reload reviews after creating
        final serviceIdToReload = _currentServiceId ?? event.serviceId;
        add(LoadReviewsEvent(serviceId: serviceIdToReload));
      },
    );
  }

  Future<void> _onUpdateReview(UpdateReviewEvent event, Emitter<ReviewState> emit) async {
    final result = await _updateReviewUseCase(
      reviewId: event.reviewId,
      rating: event.rating,
      comment: event.comment,
    );

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Review'))),
      (review) {
        emit(ReviewUpdated(review));
        // Reload reviews after updating
        final serviceIdToReload = _currentServiceId ?? review.serviceId;
        add(LoadReviewsEvent(serviceId: serviceIdToReload));
      },
    );
  }

  Future<void> _onDeleteReview(DeleteReviewEvent event, Emitter<ReviewState> emit) async {
    final result = await _deleteReviewUseCase(event.reviewId);

    result.fold(
      (failure) => emit(ReviewError(failure.toUserMessage(entityName: 'Review'))),
      (_) {
        emit(const ReviewDeleted());
        // Reload reviews after deleting
        if (_currentServiceId != null) {
          add(LoadReviewsEvent(serviceId: _currentServiceId!));
        } else if (_currentUserId != null) {
          add(LoadUserReviewsEvent(userId: _currentUserId!));
        }
      },
    );
  }

  Future<void> _onRefreshReviews(RefreshReviewsEvent event, Emitter<ReviewState> emit) async {
    if (_currentServiceId != null) {
      add(LoadReviewsEvent(serviceId: _currentServiceId!));
    } else if (_currentUserId != null) {
      add(LoadUserReviewsEvent(userId: _currentUserId!));
    }
  }
}
