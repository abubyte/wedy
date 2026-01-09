import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/review_dto.dart';

part 'review_remote_datasource.g.dart';

/// Remote data source for review API calls
@RestApi()
abstract class ReviewRemoteDataSource {
  factory ReviewRemoteDataSource(Dio dio, {String baseUrl}) = _ReviewRemoteDataSource;

  /// Get reviews for a specific service
  @GET('/api/v1/services/{serviceId}/reviews')
  Future<PaginatedReviewResponseDto> getServiceReviews(
    @Path('serviceId') String serviceId, {
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  /// Get reviews by user ID
  @GET('/api/v1/reviews')
  Future<PaginatedReviewResponseDto> getUserReviews({
    @Query('user_id') String? userId,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  /// Create a new review
  @POST('/api/v1/reviews')
  Future<ReviewDto> createReview(@Body() ReviewCreateRequestDto request);

  /// Update an existing review
  @PUT('/api/v1/reviews/{reviewId}')
  Future<ReviewDto> updateReview(@Path('reviewId') String reviewId, @Body() ReviewUpdateRequestDto request);

  /// Delete a review
  @DELETE('/api/v1/reviews/{reviewId}')
  Future<void> deleteReview(@Path('reviewId') String reviewId);
}

/// Factory function to create ReviewRemoteDataSource instance
ReviewRemoteDataSource createReviewRemoteDataSource() {
  return ReviewRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
}
