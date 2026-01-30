import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/data/datasources/service_remote_datasource.dart';
import 'package:wedy/features/service/data/models/service_dto.dart';
import 'package:wedy/features/service/data/models/user_interaction_dto.dart';
import 'package:wedy/features/service/data/repositories/service_repository_impl.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';

class MockServiceRemoteDataSource extends Mock implements ServiceRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServiceRepositoryImpl repository;
  late MockServiceRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(
      MerchantBasicInfoDto(
        id: '',
        businessName: '',
        overallRating: 0.0,
        totalReviews: 0,
        locationRegion: '',
        isVerified: false,
      ),
    );
    registerFallbackValue(
      ServiceListItemDto(
        id: '',
        name: '',
        description: '',
        price: 0.0,
        priceType: 'fixed',
        locationRegion: '',
        overallRating: 0.0,
        totalReviews: 0,
        viewCount: 0,
        likeCount: 0,
        saveCount: 0,
        createdAt: DateTime.now().toIso8601String(),
        merchant: MerchantBasicInfoDto(
          id: '',
          businessName: '',
          overallRating: 0.0,
          totalReviews: 0,
          locationRegion: '',
          isVerified: false,
        ),
        categoryId: 0,
        categoryName: '',
      ),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockServiceRemoteDataSource();
    repository = ServiceRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  final tMerchantDto = MerchantBasicInfoDto(
    id: 'merchant1',
    businessName: 'Test Merchant',
    overallRating: 4.5,
    totalReviews: 10,
    locationRegion: 'Toshkent',
    isVerified: true,
    avatarUrl: 'https://example.com/avatar.jpg',
  );

  final tServiceListItemDto = ServiceListItemDto(
    id: 'service1',
    name: 'Test Service',
    description: 'Test Description',
    price: 100000.0,
    priceType: 'fixed',
    locationRegion: 'Toshkent',
    overallRating: 4.5,
    totalReviews: 10,
    viewCount: 100,
    likeCount: 50,
    saveCount: 25,
    createdAt: DateTime.now().toIso8601String(),
    merchant: tMerchantDto,
    categoryId: 1,
    categoryName: 'Category 1',
    mainImageUrl: 'https://example.com/image.jpg',
    isFeatured: false,
  );

  final tPaginatedResponseDto = PaginatedServiceResponseDto(
    services: [tServiceListItemDto],
    total: 1,
    page: 1,
    limit: 20,
    hasMore: false,
    totalPages: 1,
  );

  final tServiceDetailDto = ServiceDetailDto(
    id: 'service1',
    name: 'Test Service',
    description: 'Test Description',
    price: 100000.0,
    priceType: 'fixed',
    locationRegion: 'Toshkent',
    latitude: 41.3111,
    longitude: 69.2797,
    viewCount: 100,
    likeCount: 50,
    saveCount: 25,
    shareCount: 10,
    overallRating: 4.5,
    totalReviews: 10,
    isActive: true,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    merchant: tMerchantDto,
    categoryId: 1,
    categoryName: 'Category 1',
    images: [
      ServiceImageDto(id: 'img1', s3Url: 'https://example.com/image1.jpg', fileName: 'image1.jpg', displayOrder: 1),
    ],
    isFeatured: false,
  );

  final tInteractionResponseDto = ServiceInteractionResponseDto(
    success: true,
    message: 'Service liked successfully',
    newCount: 51,
  );

  group('getServices', () {
    test('should return PaginatedServiceResponse when services are fetched successfully', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getServices(
          featured: any(named: 'featured'),
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          locationRegion: any(named: 'locationRegion'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          minRating: any(named: 'minRating'),
          isVerifiedMerchant: any(named: 'isVerifiedMerchant'),
          sortBy: any(named: 'sortBy'),
          sortOrder: any(named: 'sortOrder'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tPaginatedResponseDto);

      // Act
      final result = await repository.getServices();

      // Assert
      expect(result, isA<Right<Failure, PaginatedServiceResponse>>());
      final response = (result as Right).value;
      expect(response.services.length, 1);
      expect(response.services.first.id, 'service1');
      expect(response.total, 1);
      verify(
        () => mockRemoteDataSource.getServices(
          featured: null,
          query: null,
          categoryId: null,
          locationRegion: null,
          minPrice: null,
          maxPrice: null,
          minRating: null,
          isVerifiedMerchant: null,
          sortBy: null,
          sortOrder: null,
          page: 1,
          limit: 20,
        ),
      ).called(1);
    });

    test('should return ValidationFailure when API returns 400', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getServices(
          featured: any(named: 'featured'),
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          locationRegion: any(named: 'locationRegion'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          minRating: any(named: 'minRating'),
          isVerifiedMerchant: any(named: 'isVerifiedMerchant'),
          sortBy: any(named: 'sortBy'),
          sortOrder: any(named: 'sortOrder'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'detail': 'Invalid request'},
          ),
        ),
      );

      // Act
      final result = await repository.getServices();

      // Assert
      expect(result, isA<Left<Failure, PaginatedServiceResponse>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('should return AuthFailure when API returns 401', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getServices(
          featured: any(named: 'featured'),
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          locationRegion: any(named: 'locationRegion'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          minRating: any(named: 'minRating'),
          isVerifiedMerchant: any(named: 'isVerifiedMerchant'),
          sortBy: any(named: 'sortBy'),
          sortOrder: any(named: 'sortOrder'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
        ),
      );

      // Act
      final result = await repository.getServices();

      // Assert
      expect(result, isA<Left<Failure, PaginatedServiceResponse>>());
      expect((result as Left).value, isA<AuthFailure>());
    });

    test('should return NotFoundFailure when API returns 404', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getServices(
          featured: any(named: 'featured'),
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          locationRegion: any(named: 'locationRegion'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          minRating: any(named: 'minRating'),
          isVerifiedMerchant: any(named: 'isVerifiedMerchant'),
          sortBy: any(named: 'sortBy'),
          sortOrder: any(named: 'sortOrder'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'detail': 'Not found'},
          ),
        ),
      );

      // Act
      final result = await repository.getServices();

      // Assert
      expect(result, isA<Left<Failure, PaginatedServiceResponse>>());
      expect((result as Left).value, isA<NotFoundFailure>());
    });

    test('should return NetworkFailure on connection timeout', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getServices(
          featured: any(named: 'featured'),
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          locationRegion: any(named: 'locationRegion'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          minRating: any(named: 'minRating'),
          isVerifiedMerchant: any(named: 'isVerifiedMerchant'),
          sortBy: any(named: 'sortBy'),
          sortOrder: any(named: 'sortOrder'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.getServices();

      // Assert
      expect(result, isA<Left<Failure, PaginatedServiceResponse>>());
      expect((result as Left).value, isA<NetworkFailure>());
    });
  });

  group('getServiceById', () {
    test('should return Service when service is fetched successfully', () async {
      // Arrange
      const tServiceId = 'service1';
      when(() => mockRemoteDataSource.getServiceById(tServiceId)).thenAnswer((_) async => tServiceDetailDto);

      // Act
      final result = await repository.getServiceById(tServiceId);

      // Assert
      expect(result, isA<Right<Failure, Service>>());
      final service = (result as Right).value;
      expect(service.id, tServiceId);
      expect(service.name, 'Test Service');
      verify(() => mockRemoteDataSource.getServiceById(tServiceId)).called(1);
    });

    test('should return NotFoundFailure when API returns 404', () async {
      // Arrange
      const tServiceId = 'nonexistent';
      when(() => mockRemoteDataSource.getServiceById(tServiceId)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'detail': 'Service not found'},
          ),
        ),
      );

      // Act
      final result = await repository.getServiceById(tServiceId);

      // Assert
      expect(result, isA<Left<Failure, Service>>());
      expect((result as Left).value, isA<NotFoundFailure>());
    });

    test('should return NetworkFailure on connection timeout', () async {
      // Arrange
      const tServiceId = 'service1';
      when(() => mockRemoteDataSource.getServiceById(tServiceId)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.getServiceById(tServiceId);

      // Assert
      expect(result, isA<Left<Failure, Service>>());
      expect((result as Left).value, isA<NetworkFailure>());
    });
  });

  group('interactWithService', () {
    test('should return ServiceInteractionResponse when interaction is successful', () async {
      // Arrange
      const tServiceId = 'service1';
      const tInteractionType = 'like';
      when(
        () => mockRemoteDataSource.interactWithService(tServiceId, any()),
      ).thenAnswer((_) async => tInteractionResponseDto);

      // Act
      final result = await repository.interactWithService(tServiceId, tInteractionType);

      // Assert
      expect(result, isA<Right<Failure, ServiceInteractionResponse>>());
      final response = (result as Right).value;
      expect(response.success, true);
      expect(response.message, 'Service liked successfully');
      expect(response.newCount, 51);
      verify(() => mockRemoteDataSource.interactWithService(tServiceId, any())).called(1);
    });

    test('should return ValidationFailure when API returns 400', () async {
      // Arrange
      const tServiceId = 'service1';
      const tInteractionType = 'invalid';
      when(() => mockRemoteDataSource.interactWithService(tServiceId, any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'detail': 'Invalid interaction type'},
          ),
        ),
      );

      // Act
      final result = await repository.interactWithService(tServiceId, tInteractionType);

      // Assert
      expect(result, isA<Left<Failure, ServiceInteractionResponse>>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('should return NetworkFailure on connection timeout', () async {
      // Arrange
      const tServiceId = 'service1';
      const tInteractionType = 'like';
      when(() => mockRemoteDataSource.interactWithService(tServiceId, any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.interactWithService(tServiceId, tInteractionType);

      // Assert
      expect(result, isA<Left<Failure, ServiceInteractionResponse>>());
      expect((result as Left).value, isA<NetworkFailure>());
    });
  });

  group('getSavedServices', () {
    test('should return saved services when API call is successful', () async {
      // Arrange
      final tSavedServiceDto = ServiceListItemDto(
        id: 'service1',
        name: 'Test Service',
        description: 'Test Description',
        price: 100000.0,
        priceType: 'fixed',
        locationRegion: 'Toshkent',
        overallRating: 4.5,
        totalReviews: 10,
        viewCount: 100,
        likeCount: 50,
        saveCount: 25,
        createdAt: DateTime.now().toIso8601String(),
        merchant: tMerchantDto,
        categoryId: 1,
        categoryName: 'Category 1',
        mainImageUrl: 'https://example.com/image.jpg',
        isFeatured: false,
      );

      final tUserInteractionsResponseDto = UserInteractionsResponseDto(
        likedServices: [],
        savedServices: [
          UserInteractionItemDto(
            interactionType: 'save',
            interactedAt: DateTime.now().toIso8601String(),
            service: tSavedServiceDto,
          ),
        ],
        totalLiked: 0,
        totalSaved: 1,
      );

      when(() => mockRemoteDataSource.getUserInteractions()).thenAnswer((_) async => tUserInteractionsResponseDto);

      // Act
      final result = await repository.getSavedServices();

      // Assert
      expect(result, isA<Right<Failure, List<ServiceListItem>>>());
      final savedServices = (result as Right).value;
      expect(savedServices.length, 1);
      expect(savedServices[0].id, 'service1');
      expect(savedServices[0].name, 'Test Service');
      verify(() => mockRemoteDataSource.getUserInteractions()).called(1);
    });

    test('should return empty list when no saved services', () async {
      // Arrange
      final tUserInteractionsResponseDto = UserInteractionsResponseDto(
        likedServices: [],
        savedServices: [],
        totalLiked: 0,
        totalSaved: 0,
      );

      when(() => mockRemoteDataSource.getUserInteractions()).thenAnswer((_) async => tUserInteractionsResponseDto);

      // Act
      final result = await repository.getSavedServices();

      // Assert
      expect(result, isA<Right<Failure, List<ServiceListItem>>>());
      final savedServices = (result as Right).value;
      expect(savedServices, isEmpty);
      verify(() => mockRemoteDataSource.getUserInteractions()).called(1);
    });

    test('should return AuthFailure when API returns 401', () async {
      // Arrange
      when(() => mockRemoteDataSource.getUserInteractions()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
        ),
      );

      // Act
      final result = await repository.getSavedServices();

      // Assert
      expect(result, isA<Left<Failure, List<ServiceListItem>>>());
      expect((result as Left).value, isA<AuthFailure>());
    });

    test('should return NetworkFailure on connection timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.getUserInteractions()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.getSavedServices();

      // Assert
      expect(result, isA<Left<Failure, List<ServiceListItem>>>());
      expect((result as Left).value, isA<NetworkFailure>());
    });

    test('should return ServerFailure when server error occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getUserInteractions()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'detail': 'Internal server error'},
          ),
        ),
      );

      // Act
      final result = await repository.getSavedServices();

      // Assert
      expect(result, isA<Left<Failure, List<ServiceListItem>>>());
      expect((result as Left).value, isA<ServerFailure>());
    });
  });
}
