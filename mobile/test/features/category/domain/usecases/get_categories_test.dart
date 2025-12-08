import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/category/domain/repositories/category_repository.dart';
import 'package:wedy/features/category/domain/usecases/get_categories.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetCategories useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetCategories(mockRepository);
  });

  const tCategory1 = ServiceCategory(
    id: 1,
    name: 'Photography',
    description: 'Wedding photography services',
    iconUrl: 'https://example.com/icon1.jpg',
    displayOrder: 1,
    serviceCount: 10,
  );

  const tCategory2 = ServiceCategory(
    id: 2,
    name: 'Videography',
    description: 'Wedding video recording services',
    iconUrl: 'https://example.com/icon2.jpg',
    displayOrder: 2,
    serviceCount: 5,
  );

  const tCategoriesResponse = CategoriesResponse(categories: [tCategory1, tCategory2], total: 2);

  test('should get categories successfully', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenAnswer((_) async => const Right(tCategoriesResponse));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Right(tCategoriesResponse));
    verify(() => mockRepository.getCategories()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.getCategories()).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
    verify(() => mockRepository.getCategories()).called(1);
  });

  test('should return NotFoundFailure when categories not found', () async {
    // Arrange
    when(
      () => mockRepository.getCategories(),
    ).thenAnswer((_) async => const Left(NotFoundFailure('Categories not found')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(NotFoundFailure('Categories not found')));
    verify(() => mockRepository.getCategories()).called(1);
  });

  test('should return AuthFailure when authentication fails', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left(AuthFailure('Unauthorized')));
    verify(() => mockRepository.getCategories()).called(1);
  });

  test('should return empty categories list successfully', () async {
    // Arrange
    const emptyResponse = CategoriesResponse(categories: [], total: 0);
    when(() => mockRepository.getCategories()).thenAnswer((_) async => const Right(emptyResponse));

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Right(emptyResponse));
    expect(result.fold((l) => null, (r) => r.categories), isEmpty);
    verify(() => mockRepository.getCategories()).called(1);
  });
}
