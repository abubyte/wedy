import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wedy/core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_dto.dart';

part 'category_remote_datasource.g.dart';

/// Remote data source for category API calls
@RestApi()
abstract class CategoryRemoteDataSource {
  factory CategoryRemoteDataSource(Dio dio, {String baseUrl}) = _CategoryRemoteDataSource;

  /// Get all active service categories with service counts
  @GET('/api/v1/categories/')
  Future<CategoriesResponseDto> getCategories();
}

/// Factory function to create CategoryRemoteDataSource instance
CategoryRemoteDataSource createCategoryRemoteDataSource() {
  return CategoryRemoteDataSource(ApiClient.instance, baseUrl: ApiConstants.baseUrl);
}
