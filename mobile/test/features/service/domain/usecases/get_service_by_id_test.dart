import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';
import 'package:wedy/features/service/domain/usecases/get_service_by_id.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late GetServiceById useCase;
  late MockServiceRepository mockRepository;

  setUp(() {
    mockRepository = MockServiceRepository();
    useCase = GetServiceById(mockRepository);
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

  final tService = Service(
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
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    merchant: tMerchant,
    categoryId: 1,
    categoryName: 'Category 1',
    images: [
      ServiceImage(id: 'img1', s3Url: 'https://example.com/image1.jpg', fileName: 'image1.jpg', displayOrder: 1),
    ],
    isFeatured: false,
  );

  test('should get service by id successfully', () async {
    // Arrange
    const tServiceId = 'service1';
    when(() => mockRepository.getServiceById(tServiceId)).thenAnswer((_) async => Right(tService));

    // Act
    final result = await useCase(tServiceId);

    // Assert
    expect(result, Right(tService));
    verify(() => mockRepository.getServiceById(tServiceId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when service id is empty', () async {
    // Act
    final result = await useCase('');

    // Assert
    expect(result, const Left(ValidationFailure('Service ID cannot be empty')));
    verifyNever(() => mockRepository.getServiceById(any()));
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    const tServiceId = 'service1';
    when(
      () => mockRepository.getServiceById(tServiceId),
    ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(tServiceId);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.getServiceById(tServiceId)).called(1);
  });

  test('should return NotFoundFailure when service not found', () async {
    // Arrange
    const tServiceId = 'nonexistent';
    when(
      () => mockRepository.getServiceById(tServiceId),
    ).thenAnswer((_) async => const Left(NotFoundFailure('Service not found')));

    // Act
    final result = await useCase(tServiceId);

    // Assert
    expect(result, const Left(NotFoundFailure('Service not found')));
    verify(() => mockRepository.getServiceById(tServiceId)).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    const tServiceId = 'service1';
    when(
      () => mockRepository.getServiceById(tServiceId),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(tServiceId);

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.getServiceById(tServiceId)).called(1);
  });
}
