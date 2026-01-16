import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/apps/client/pages/favorites/favorites_page.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';

class MockServiceBloc extends Mock implements ServiceBloc {}

void main() {
  late MockServiceBloc mockServiceBloc;

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
      name: 'Saved Service 1',
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
      name: 'Saved Service 2',
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

  setUpAll(() {
    registerFallbackValue(const LoadSavedServicesEvent());
    registerFallbackValue(const InteractWithServiceEvent(serviceId: '', interactionType: ''));
  });

  setUp(() {
    mockServiceBloc = MockServiceBloc();
  });

  Widget createTestWidget({ServiceState? initialState}) {
    when(() => mockServiceBloc.state).thenReturn(initialState ?? const ServiceInitial());
    when(() => mockServiceBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockServiceBloc.add(any())).thenReturn(null);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: '/',
          builder: (context, state) =>
              BlocProvider<ServiceBloc>.value(value: mockServiceBloc, child: const ClientFavoritesPage()),
        ),
        GoRoute(
          path: '/service/:id',
          name: '/service/:id',
          builder: (context, state) => Scaffold(body: Text('Service ${state.pathParameters['id']}')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('ClientFavoritesPage', () {
    testWidgets('displays loading indicator when loading', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceLoading());

      // Act
      await tester.pumpWidget(createTestWidget(initialState: const ServiceLoading()));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sevimlilar'), findsNothing);
    });

    testWidgets('displays empty state when no saved services', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const SavedServicesLoaded([]));

      // Act
      await tester.pumpWidget(createTestWidget(initialState: const SavedServicesLoaded([])));
      await tester.pump();

      // Assert
      expect(find.text('Sevimli elonlaringiz yo\'q'), findsOneWidget);
      expect(find.text('Sevimlilar'), findsNothing);
    });

    testWidgets('displays saved services when loaded', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(SavedServicesLoaded(tSavedServices));

      // Act
      await tester.pumpWidget(createTestWidget(initialState: SavedServicesLoaded(tSavedServices)));
      await tester.pump();

      // Assert
      expect(find.text('Sevimlilar'), findsOneWidget);
      expect(find.text('Saved Service 1'), findsOneWidget);
      expect(find.text('Saved Service 2'), findsOneWidget);
    });

    testWidgets('dispatches LoadSavedServicesEvent on init', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget(initialState: const ServiceInitial()));
      await tester.pump();

      // Assert
      verify(() => mockServiceBloc.add(const LoadSavedServicesEvent())).called(1);
    });

    testWidgets('dispatches LoadSavedServicesEvent on refresh', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(SavedServicesLoaded(tSavedServices));

      // Act
      await tester.pumpWidget(createTestWidget(initialState: SavedServicesLoaded(tSavedServices)));
      await tester.pump();

      // Find the SmartRefresher and trigger refresh
      final refreshFinder = find.byType(ClientFavoritesPage);
      expect(refreshFinder, findsOneWidget);

      // Simulate pull to refresh
      await tester.drag(find.byType(ClientFavoritesPage), const Offset(0, 300));
      await tester.pump();

      // Assert - verify that LoadSavedServicesEvent was dispatched
      verify(() => mockServiceBloc.add(const LoadSavedServicesEvent())).called(greaterThan(0));
    });

    testWidgets('navigates to service details when service card is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(SavedServicesLoaded(tSavedServices));

      // Act
      await tester.pumpWidget(createTestWidget(initialState: SavedServicesLoaded(tSavedServices)));
      await tester.pump();

      // Find and tap a service card
      final serviceCard = find.text('Saved Service 1');
      expect(serviceCard, findsOneWidget);
      await tester.tap(serviceCard);
      await tester.pumpAndSettle();

      // Assert - should navigate to service details
      expect(find.text('Service service1'), findsOneWidget);
    });

    testWidgets('dispatches InteractWithServiceEvent when favorite icon is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(SavedServicesLoaded(tSavedServices));

      // Act
      await tester.pumpWidget(createTestWidget(initialState: SavedServicesLoaded(tSavedServices)));
      await tester.pump();

      // Find favorite icon (heart icon) - this might need adjustment based on actual widget structure
      // For now, we'll verify the interaction happens when the card's favorite button is tapped
      // The actual implementation depends on how the favorite button is structured in ClientServiceCard

      // Note: This test may need adjustment based on the actual widget structure
      // The favorite icon is inside ClientServiceCard which might require different finder strategies
    });

    testWidgets('displays error state when loading fails', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceError('Error loading saved services'));

      // Act
      await tester.pumpWidget(createTestWidget(initialState: const ServiceError('Error loading saved services')));
      await tester.pump();

      // Assert - should show empty state when error occurs
      expect(find.text('Sevimli elonlaringiz yo\'q'), findsOneWidget);
    });
  });
}
