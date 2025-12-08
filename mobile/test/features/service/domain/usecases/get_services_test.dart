import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';
import 'package:wedy/features/service/domain/usecases/get_services.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late GetServices useCase;
  late MockServiceRepository mockRepository;

  setUp(() {
    mockRepository = MockServiceRepository();
    useCase = GetServices(mockRepository);
  });

  final tMerchant = MerchantBasicInfo(
    id: 'merchant1',
    businessName: 'Test Merchant',
    overallRating: 4.5,
    totalReviews: 10,
    locationRegion: 'Toshkent',
    isVerified: true,
    avatarUrl: 'https://example.com/avatar.jpg',
  );

  final tServiceListItem = ServiceListItem(
    id: 'service1',
    name: 'Test Service',
    description: 'Test Description',
    price: 100000.0,
    locationRegion: 'Toshkent',
    overallRating: 4.5,
    totalReviews: 10,
    viewCount: 100,
    likeCount: 50,
    saveCount: 25,
    createdAt: DateTime.now(),
    merchant: tMerchant,
    categoryId: 1,
    categoryName: 'Category 1',
    mainImageUrl: 'https://example.com/image.jpg',
    isFeatured: false,
  );

  final tPaginatedResponse = PaginatedServiceResponse(
    services: [tServiceListItem],
    total: 1,
    page: 1,
    limit: 20,
    hasMore: false,
    totalPages: 1,
  );

  test('should get services successfully', () async {
    // Arrange
    when(
      () => mockRepository.getServices(
        featured: any(named: 'featured'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => Right(tPaginatedResponse));

    // Act
    final result = await useCase();

    // Assert
    expect(result, Right(tPaginatedResponse));
    verify(() => mockRepository.getServices(featured: null, filters: null, page: 1, limit: 20)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should get featured services successfully', () async {
    // Arrange
    when(
      () => mockRepository.getServices(
        featured: true,
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => Right(tPaginatedResponse));

    // Act
    final result = await useCase(featured: true);

    // Assert
    expect(result, Right(tPaginatedResponse));
    verify(() => mockRepository.getServices(featured: true, filters: null, page: 1, limit: 20)).called(1);
  });

  test('should get services with filters successfully', () async {
    // Arrange
    final filters = ServiceSearchFilters(
      query: 'test',
      categoryId: 1,
      locationRegion: 'Toshkent',
      minPrice: 50000.0,
      maxPrice: 200000.0,
      minRating: 4.0,
      isVerifiedMerchant: true,
      sortBy: 'price',
      sortOrder: 'asc',
    );
    when(
      () => mockRepository.getServices(
        featured: any(named: 'featured'),
        filters: filters,
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => Right(tPaginatedResponse));

    // Act
    final result = await useCase(filters: filters);

    // Assert
    expect(result, Right(tPaginatedResponse));
    verify(() => mockRepository.getServices(featured: null, filters: filters, page: 1, limit: 20)).called(1);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.getServices(
        featured: any(named: 'featured'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.getServices(featured: null, filters: null, page: 1, limit: 20)).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    when(
      () => mockRepository.getServices(
        featured: any(named: 'featured'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.getServices(featured: null, filters: null, page: 1, limit: 20)).called(1);
  });

  test('should get services with custom page and limit', () async {
    // Arrange
    when(
      () => mockRepository.getServices(
        featured: any(named: 'featured'),
        filters: any(named: 'filters'),
        page: 2,
        limit: 10,
      ),
    ).thenAnswer((_) async => Right(tPaginatedResponse));

    // Act
    final result = await useCase(page: 2, limit: 10);

    // Assert
    expect(result, Right(tPaginatedResponse));
    verify(() => mockRepository.getServices(featured: null, filters: null, page: 2, limit: 10)).called(1);
  });
}
