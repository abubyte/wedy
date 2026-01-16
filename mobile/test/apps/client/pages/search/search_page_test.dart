import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/apps/client/pages/search/search_page.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_event.dart';
import 'package:wedy/features/category/presentation/bloc/category_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class MockServiceBloc extends Mock implements ServiceBloc {}

class MockCategoryBloc extends Mock implements CategoryBloc {}

void main() {
  late MockServiceBloc mockServiceBloc;
  late MockCategoryBloc mockCategoryBloc;

  final tMerchant = MerchantBasicInfo(
    id: 'merchant1',
    businessName: 'Test Merchant',
    overallRating: 4.5,
    totalReviews: 10,
    locationRegion: 'Toshkent',
    isVerified: true,
    avatarUrl: 'https://example.com/avatar.jpg',
  );

  final tServices = [
    ServiceListItem(
      id: 'service1',
      name: 'Test Service 1',
      description: 'Description 1',
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
      description: 'Description 2',
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

  final tPaginatedResponse = PaginatedServiceResponse(
    services: tServices,
    total: 2,
    page: 1,
    limit: 20,
    hasMore: false,
    totalPages: 1,
  );

  final tCategories = [
    const ServiceCategory(
      id: 1,
      name: 'Category 1',
      displayOrder: 1,
    ),
    const ServiceCategory(
      id: 2,
      name: 'Category 2',
      displayOrder: 2,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const LoadSavedServicesEvent());
    registerFallbackValue(const LoadServicesEvent());
    registerFallbackValue(const LoadCategoriesEvent());
  });

  setUp(() {
    mockServiceBloc = MockServiceBloc();
    mockCategoryBloc = MockCategoryBloc();
  });

  Widget createTestWidget({ServiceState? serviceState, CategoryState? categoryState, String? initialQuery}) {
    when(() => mockServiceBloc.state).thenReturn(serviceState ?? const ServiceInitial());
    when(() => mockServiceBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockServiceBloc.add(any())).thenReturn(null);

    when(() => mockCategoryBloc.state).thenReturn(categoryState ?? const CategoryInitial());
    when(() => mockCategoryBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCategoryBloc.add(any())).thenReturn(null);

    // Create a test widget that doesn't use getIt
    final testWidget = MultiBlocProvider(
      providers: [
        BlocProvider<ServiceBloc>.value(value: mockServiceBloc),
        BlocProvider<CategoryBloc>.value(value: mockCategoryBloc),
      ],
      child: ClientSearchPage(initialQuery: initialQuery),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: '/',
          builder: (context, state) => testWidget,
        ),
        GoRoute(
          path: '/service/:id',
          name: '/service/:id',
          builder: (context, state) => Scaffold(
            body: Text('Service ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('ClientSearchPage', () {
    testWidgets('displays search field and filter button', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(IconsaxPlusLinear.filter), findsOneWidget);
      expect(find.byIcon(IconsaxPlusLinear.search_normal_1), findsOneWidget);
    });

    testWidgets('displays loading indicator when loading', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceLoading());

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: const ServiceLoading()));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no results', (WidgetTester tester) async {
      // Arrange
      final emptyResponse = PaginatedServiceResponse(
        services: [],
        total: 0,
        page: 1,
        limit: 20,
        hasMore: false,
        totalPages: 0,
      );
      when(() => mockServiceBloc.state).thenReturn(ServicesLoaded(response: emptyResponse, allServices: const []));

      // Act
      await tester.pumpWidget(createTestWidget(
        serviceState: ServicesLoaded(response: emptyResponse, allServices: const []),
      ));
      await tester.pump();

      // Assert
      expect(find.text('Qidiruv natijalari topilmadi'), findsOneWidget);
    });

    testWidgets('displays search results when loaded', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServicesLoaded(response: tPaginatedResponse, allServices: tServices));

      // Act
      await tester.pumpWidget(createTestWidget(
        serviceState: ServicesLoaded(response: tPaginatedResponse, allServices: tServices),
      ));
      await tester.pump();

      // Assert
      expect(find.text('Test Service 1'), findsOneWidget);
      expect(find.text('Test Service 2'), findsOneWidget);
    });

    testWidgets('displays error state when search fails', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceError('Search failed'));

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: const ServiceError('Search failed')));
      await tester.pump();

      // Assert
      expect(find.text('Search failed'), findsOneWidget);
      expect(find.text('Qayta urinish'), findsOneWidget);
    });

    testWidgets('performs search when search button is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap search button
      final searchButton = find.byIcon(IconsaxPlusLinear.search_normal_1);
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await tester.pump();

      // Assert - verify LoadServicesEvent was dispatched
      verify(() => mockServiceBloc.add(any(that: isA<LoadServicesEvent>()))).called(greaterThanOrEqualTo(1));
    });

    testWidgets('opens filters sheet when filter button is tapped', (WidgetTester tester) async {
      // Arrange
      final categoriesResponse = CategoriesResponse(categories: tCategories, total: 2);
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());
      when(() => mockCategoryBloc.state).thenReturn(CategoriesLoaded(categoriesResponse));

      // Act
      await tester.pumpWidget(createTestWidget(
        categoryState: CategoriesLoaded(categoriesResponse),
      ));
      await tester.pump();

      // Find and tap filter button
      final filterButton = find.byIcon(IconsaxPlusLinear.filter);
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Assert - filters sheet should be visible
      expect(find.text('Filtrlar'), findsOneWidget);
    });

    testWidgets('initializes with query if provided', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget(initialQuery: 'test query'));
      await tester.pump();

      // Assert - verify LoadServicesEvent was dispatched with query
      verify(() => mockServiceBloc.add(any(that: isA<LoadServicesEvent>()))).called(greaterThanOrEqualTo(1));
    });

    testWidgets('navigates to service details when service card is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServicesLoaded(response: tPaginatedResponse, allServices: tServices));

      // Act
      await tester.pumpWidget(createTestWidget(
        serviceState: ServicesLoaded(response: tPaginatedResponse, allServices: tServices),
      ));
      await tester.pump();

      // Find and tap a service card
      final serviceCard = find.text('Test Service 1');
      expect(serviceCard, findsOneWidget);
      await tester.tap(serviceCard);
      await tester.pumpAndSettle();

      // Assert - should navigate to service details
      expect(find.text('Service service1'), findsOneWidget);
    });

    testWidgets('shows filter button', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServicesLoaded(
        response: tPaginatedResponse,
        allServices: tServices,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(
        serviceState: ServicesLoaded(response: tPaginatedResponse, allServices: tServices),
      ));
      await tester.pump();

      // Assert - filter button should be visible
      expect(find.byIcon(IconsaxPlusLinear.filter), findsOneWidget);
    });
  });
}

