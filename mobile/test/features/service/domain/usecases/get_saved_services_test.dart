import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';
import 'package:wedy/features/service/domain/usecases/get_saved_services.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late GetSavedServices useCase;
  late MockServiceRepository mockRepository;

  setUp(() {
    mockRepository = MockServiceRepository();
    useCase = GetSavedServices(mockRepository);
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

  final tSavedServices = [
    ServiceListItem(
      id: 'service1',
      name: 'Test Service 1',
      description: 'Test Description 1',
      price: 100000.0,
      priceType: 'fixed',
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
      mainImageUrl: 'https://example.com/image1.jpg',
      isFeatured: false,
    ),
    ServiceListItem(
      id: 'service2',
      name: 'Test Service 2',
      description: 'Test Description 2',
      price: 200000.0,
      priceType: 'fixed',
      locationRegion: 'Samarqand',
      overallRating: 4.8,
      totalReviews: 15,
      viewCount: 200,
      likeCount: 75,
      saveCount: 30,
      createdAt: DateTime.now(),
      merchant: tMerchant,
      categoryId: 2,
      categoryName: 'Category 2',
      mainImageUrl: 'https://example.com/image2.jpg',
      isFeatured: true,
    ),
  ];

  test('should get saved services successfully', () async {
    // Arrange
    when(() => mockRepository.getSavedServices()).thenAnswer((_) async => Right(tSavedServices));

    // Act
    final result = await useCase();

    // Assert
    expect(result, Right(tSavedServices));
    verify(() => mockRepository.getSavedServices()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no saved services', () async {
    // Arrange
    when(() => mockRepository.getSavedServices()).thenAnswer((_) async => const Right(<ServiceListItem>[]));

    // Act
    final result = await useCase();

    // Assert
    expect(result, isA<Right<Failure, List<ServiceListItem>>>());
    final savedServices = (result as Right).value;
    expect(savedServices, isEmpty);
    verify(() => mockRepository.getSavedServices()).called(1);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(() => mockRepository.getSavedServices())
        .thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.getSavedServices()).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    when(() => mockRepository.getSavedServices())
        .thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.getSavedServices()).called(1);
  });

  test('should return AuthFailure when unauthorized', () async {
    // Arrange
    when(() => mockRepository.getSavedServices())
        .thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(AuthFailure('Unauthorized')));
    verify(() => mockRepository.getSavedServices()).called(1);
  });
}

