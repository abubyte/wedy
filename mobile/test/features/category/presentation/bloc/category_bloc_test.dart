import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/category/domain/usecases/get_categories.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_event.dart';
import 'package:wedy/features/category/presentation/bloc/category_state.dart';

class MockGetCategories extends Mock implements GetCategories {}

void main() {
  late CategoryBloc bloc;
  late MockGetCategories mockGetCategories;

  setUp(() {
    mockGetCategories = MockGetCategories();
    bloc = CategoryBloc(getCategoriesUseCase: mockGetCategories);
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

  test('initial state should be CategoryInitial', () {
    expect(bloc.state, const CategoryInitial());
  });

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoriesLoaded] when LoadCategoriesEvent is successful',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Right(tCategoriesResponse));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [const CategoryLoading(), const CategoriesLoaded(tCategoriesResponse)],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoryError] when LoadCategoriesEvent fails with NetworkFailure',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [
      const CategoryLoading(),
      const CategoryError('Network error. Please check your internet connection.'),
    ],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoryError] when LoadCategoriesEvent fails with ServerFailure',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Left(ServerFailure('Server error')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [const CategoryLoading(), const CategoryError('Server error. Please try again later.')],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoryError] when LoadCategoriesEvent fails with NotFoundFailure',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Left(NotFoundFailure('Categories not found')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [const CategoryLoading(), const CategoryError('Categories not found.')],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoryError] when LoadCategoriesEvent fails with AuthFailure',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [const CategoryLoading(), const CategoryError('Authentication failed. Please login again.')],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoryError] when LoadCategoriesEvent fails with ValidationFailure',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Left(ValidationFailure('Invalid request')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [const CategoryLoading(), const CategoryError('Invalid request')],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoriesLoaded] with empty list when categories are empty',
    build: () {
      const emptyResponse = CategoriesResponse(categories: [], total: 0);
      when(() => mockGetCategories()).thenAnswer((_) async => const Right(emptyResponse));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadCategoriesEvent()),
    expect: () => [const CategoryLoading(), const CategoriesLoaded(CategoriesResponse(categories: [], total: 0))],
    verify: (_) {
      verify(() => mockGetCategories()).called(1);
    },
  );

  blocTest<CategoryBloc, CategoryState>(
    'should handle multiple LoadCategoriesEvent calls',
    build: () {
      when(() => mockGetCategories()).thenAnswer((_) async => const Right(tCategoriesResponse));
      return bloc;
    },
    act: (bloc) {
      bloc.add(const LoadCategoriesEvent());
      bloc.add(const LoadCategoriesEvent());
    },
    expect: () => [
      const CategoryLoading(),
      const CategoriesLoaded(tCategoriesResponse),
      const CategoryLoading(),
      const CategoriesLoaded(tCategoriesResponse),
    ],
    verify: (_) {
      verify(() => mockGetCategories()).called(2);
    },
  );
}
