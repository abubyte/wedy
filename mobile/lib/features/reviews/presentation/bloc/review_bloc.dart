import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_reviews.dart';
import '../../domain/usecases/get_user_reviews.dart';
import '../../domain/usecases/create_review.dart';
import '../../domain/usecases/update_review.dart';
import '../../domain/usecases/delete_review.dart';
import '../../domain/entities/review.dart';
import 'review_event.dart';
import 'review_state.dart';

/// Review BLoC for managing review state
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final GetReviews getReviewsUseCase;
  final GetUserReviews getUserReviewsUseCase;
  final CreateReview createReviewUseCase;
  final UpdateReview updateReviewUseCase;
  final DeleteReview deleteReviewUseCase;

  // Store accumulated reviews for pagination
  List<Review> _accumulatedReviews = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentServiceId;
  String? _currentUserId;

  ReviewBloc({
    required this.getReviewsUseCase,
    required this.getUserReviewsUseCase,
    required this.createReviewUseCase,
    required this.updateReviewUseCase,
    required this.deleteReviewUseCase,
  }) : super(const ReviewInitial()) {
    on<LoadReviewsEvent>(_onLoadReviews);
    on<LoadMoreReviewsEvent>(_onLoadMoreReviews);
    on<LoadUserReviewsEvent>(_onLoadUserReviews);
    on<LoadMoreUserReviewsEvent>(_onLoadMoreUserReviews);
    on<CreateReviewEvent>(_onCreateReview);
    on<UpdateReviewEvent>(_onUpdateReview);
    on<DeleteReviewEvent>(_onDeleteReview);
    on<RefreshReviewsEvent>(_onRefreshReviews);
  }

  Future<void> _onLoadReviews(LoadReviewsEvent event, Emitter<ReviewState> emit) async {
    emit(const ReviewLoading());

    // Reset accumulated reviews for new load
    _accumulatedReviews = [];
    _currentPage = 1;
    _hasMore = true;
    _currentServiceId = event.serviceId;

    final result = await getReviewsUseCase(serviceId: event.serviceId, page: event.page, limit: event.limit);

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
      (response) {
        _accumulatedReviews = List.from(response.reviews);
        _currentPage = response.page;
        _hasMore = response.hasMore;
        emit(ReviewsLoaded(response: response, allReviews: _accumulatedReviews));
      },
    );
  }

  Future<void> _onLoadMoreReviews(LoadMoreReviewsEvent event, Emitter<ReviewState> emit) async {
    if (!_hasMore || state is ReviewLoading || _currentServiceId == null) return;

    final nextPage = _currentPage + 1;

    final result = await getReviewsUseCase(serviceId: _currentServiceId!, page: nextPage, limit: 20);

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
      (response) {
        _accumulatedReviews.addAll(response.reviews);
        _currentPage = response.page;
        _hasMore = response.hasMore;
        emit(ReviewsLoaded(response: response, allReviews: _accumulatedReviews));
      },
    );
  }

  Future<void> _onCreateReview(CreateReviewEvent event, Emitter<ReviewState> emit) async {
    final result = await createReviewUseCase(
      serviceId: event.serviceId,
      rating: event.rating,
      comment: event.comment,
    );

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
      (review) {
        emit(ReviewCreated(review));
        // Reload reviews after creating - use event.serviceId if _currentServiceId is not set
        final serviceIdToReload = _currentServiceId ?? event.serviceId;
        add(LoadReviewsEvent(serviceId: serviceIdToReload));
      },
    );
  }

  Future<void> _onUpdateReview(UpdateReviewEvent event, Emitter<ReviewState> emit) async {
    final result = await updateReviewUseCase(
      reviewId: event.reviewId,
      rating: event.rating,
      comment: event.comment,
    );

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
      (review) {
        emit(ReviewUpdated(review));
        // Reload reviews after updating - use review.serviceId if _currentServiceId is not set
        final serviceIdToReload = _currentServiceId ?? review.serviceId;
        add(LoadReviewsEvent(serviceId: serviceIdToReload));
      },
    );
  }

  Future<void> _onDeleteReview(DeleteReviewEvent event, Emitter<ReviewState> emit) async {
    final result = await deleteReviewUseCase(event.reviewId);

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
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

  Future<void> _onLoadUserReviews(LoadUserReviewsEvent event, Emitter<ReviewState> emit) async {
    emit(const ReviewLoading());

    // Reset accumulated reviews for new load
    _accumulatedReviews = [];
    _currentPage = 1;
    _hasMore = true;
    _currentUserId = event.userId;
    _currentServiceId = null; // Clear service ID when loading user reviews

    final result = await getUserReviewsUseCase(userId: event.userId, page: event.page, limit: event.limit);

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
      (response) {
        _accumulatedReviews = List.from(response.reviews);
        _currentPage = response.page;
        _hasMore = response.hasMore;
        emit(ReviewsLoaded(response: response, allReviews: _accumulatedReviews));
      },
    );
  }

  Future<void> _onLoadMoreUserReviews(LoadMoreUserReviewsEvent event, Emitter<ReviewState> emit) async {
    if (!_hasMore || state is ReviewLoading || _currentUserId == null) return;

    final nextPage = _currentPage + 1;

    final result = await getUserReviewsUseCase(userId: _currentUserId!, page: nextPage, limit: 20);

    result.fold(
      (failure) => emit(ReviewError(_getErrorMessage(failure))),
      (response) {
        _accumulatedReviews.addAll(response.reviews);
        _currentPage = response.page;
        _hasMore = response.hasMore;
        emit(ReviewsLoaded(response: response, allReviews: _accumulatedReviews));
      },
    );
  }

  Future<void> _onRefreshReviews(RefreshReviewsEvent event, Emitter<ReviewState> emit) async {
    // Reset and reload
    if (_currentServiceId != null) {
      add(LoadReviewsEvent(serviceId: _currentServiceId!));
    } else if (_currentUserId != null) {
      add(LoadUserReviewsEvent(userId: _currentUserId!));
    }
  }

  String _getErrorMessage(dynamic failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your internet connection.';
    } else if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is NotFoundFailure) {
      return 'Review not found.';
    } else if (failure is AuthFailure) {
      return 'Authentication failed. Please login again.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred.';
  }
}

