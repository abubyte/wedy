import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/gallery_dto.dart';

part 'gallery_remote_datasource.g.dart';

/// Remote data source for gallery API calls
@RestApi()
abstract class GalleryRemoteDataSource {
  factory GalleryRemoteDataSource(Dio dio, {String baseUrl}) =
      _GalleryRemoteDataSource;

  /// Get all gallery images
  @GET('/api/v1/merchants/gallery')
  Future<List<GalleryImageDto>> getGalleryImages();

  /// Add gallery image
  @POST('/api/v1/merchants/gallery')
  @MultiPart()
  Future<ImageUploadResponseDto> addGalleryImage(
    @Part(name: 'file') File file,
    @Part(name: 'display_order') int displayOrder,
  );

  /// Delete gallery image
  @DELETE('/api/v1/merchants/gallery/{imageId}')
  Future<void> deleteGalleryImage(@Path('imageId') String imageId);
}

/// Factory function to create GalleryRemoteDataSource instance
GalleryRemoteDataSource createGalleryRemoteDataSource() {
  return GalleryRemoteDataSource(ApiClient.instance,
      baseUrl: ApiConstants.baseUrl);
}
