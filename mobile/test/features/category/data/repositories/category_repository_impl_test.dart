import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/category/data/datasources/category_remote_datasource.dart';
import 'package:wedy/features/category/data/models/category_dto.dart';
import 'package:wedy/features/category/data/repositories/category_repository_impl.dart';
import 'package:wedy/features/category/domain/entities/category.dart';

class MockCategoryRemoteDataSource extends Mock implements CategoryRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryRepositoryImpl repository;
  late MockCategoryRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(const ServiceCategoryDto(id: 0, name: '', displayOrder: 0));
  });

  setUp(() {
    mockRemoteDataSource = MockCategoryRemoteDataSource();
    repository = CategoryRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tCategoryDto1 = ServiceCategoryDto(
    id: 1,
    name: 'Photography',
    description: 'Wedding photography services',
    iconUrl: 'https://example.com/icon1.jpg',
    displayOrder: 1,
    serviceCount: 10,
  );

  const tCategoryDto2 = ServiceCategoryDto(
    id: 2,
    name: 'Videography',
    description: 'Wedding video recording services',
    iconUrl: 'https://example.com/icon2.jpg',
    displayOrder: 2,
    serviceCount: 5,
  );

  const tCategoriesResponseDto = CategoriesResponseDto(categories: [tCategoryDto1, tCategoryDto2], total: 2);

  const tCategoriesResponse = CategoriesResponse(
    categories: [
      ServiceCategory(
        id: 1,
        name: 'Photography',
        description: 'Wedding photography services',
        iconUrl: 'https://example.com/icon1.jpg',
        displayOrder: 1,
        serviceCount: 10,
      ),
      ServiceCategory(
        id: 2,
        name: 'Videography',
        description: 'Wedding video recording services',
        iconUrl: 'https://example.com/icon2.jpg',
        displayOrder: 2,
        serviceCount: 5,
      ),
    ],
    total: 2,
  );

  group('getCategories', () {
    test('should return CategoriesResponse when remote data source succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenAnswer((_) async => tCategoriesResponseDto);

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, const Right(tCategoriesResponse));
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return NetworkFailure when connection timeout occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return NetworkFailure when receive timeout occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return AuthFailure when status code is 401', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: ''), statusCode: 401),
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<AuthFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return NotFoundFailure when status code is 404', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: ''), statusCode: 404),
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<NotFoundFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return ValidationFailure when status code is 400', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'detail': 'Invalid request'},
          ),
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<ValidationFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return ServerFailure when status code is 500', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: ''), statusCode: 500),
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return NetworkFailure when request is cancelled', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.cancel,
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return NetworkFailure when SocketException occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.unknown,
          message: 'SocketException: Failed host lookup',
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return ServerFailure when unknown error occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.unknown,
          message: 'Unknown error',
        ),
      );

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return ServerFailure when non-DioException occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCategories()).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Left<Failure, CategoriesResponse>>());
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });

    test('should return empty categories list successfully', () async {
      // Arrange
      const emptyResponseDto = CategoriesResponseDto(categories: [], total: 0);
      when(() => mockRemoteDataSource.getCategories()).thenAnswer((_) async => emptyResponseDto);

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<Right<Failure, CategoriesResponse>>());
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.categories, isEmpty);
        expect(r.total, 0);
      });
      verify(() => mockRemoteDataSource.getCategories()).called(1);
    });
  });
}
