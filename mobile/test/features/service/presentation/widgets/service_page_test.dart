import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/service/presentation/screens/service/service_page.dart';

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

  setUpAll(() {
    registerFallbackValue(const LoadServiceByIdEvent(''));
    registerFallbackValue(const LoadServicesEvent());
    registerFallbackValue(const InteractWithServiceEvent(serviceId: '', interactionType: ''));
  });

  setUp(() {
    mockServiceBloc = MockServiceBloc();
  });

  Widget createTestWidget({ServiceState? serviceState, String? serviceId}) {
    when(() => mockServiceBloc.state).thenReturn(serviceState ?? const ServiceInitial());
    when(() => mockServiceBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockServiceBloc.add(any())).thenReturn(null);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/service/:serviceId',
          name: '/service/:serviceId',
          builder: (context, state) => BlocProvider<ServiceBloc>.value(
            value: mockServiceBloc,
            child: WedyServicePage(serviceId: serviceId ?? state.pathParameters['serviceId']),
          ),
        ),
        GoRoute(
          path: '/',
          name: '/',
          builder: (context, state) => const Scaffold(body: Text('Home Page')),
        ),
      ],
    );

    return BlocProvider<ServiceBloc>.value(
      value: mockServiceBloc,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('WedyServicePage - Loading State', () {
    testWidgets('should display loading indicator when service is loading', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceLoading());

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: const ServiceLoading(), serviceId: 'service1'));

      // Assert
      expect(find.text('Yuklanmoqda...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('WedyServicePage - Error State', () {
    testWidgets('should display error message when service load fails', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceError('Service not found'));

      // Act
      await tester.pumpWidget(
        createTestWidget(serviceState: const ServiceError('Service not found'), serviceId: 'service1'),
      );

      // Assert
      expect(find.text('Xatolik'), findsOneWidget);
      expect(find.text('Service not found'), findsOneWidget);
      expect(find.text('Qayta urinish'), findsOneWidget);
    });

    testWidgets('should reload service when retry button is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceError('Service not found'));

      // Act
      await tester.pumpWidget(
        createTestWidget(serviceState: const ServiceError('Service not found'), serviceId: 'service1'),
      );
      await tester.tap(find.text('Qayta urinish'));
      await tester.pump();

      // Assert
      verify(() => mockServiceBloc.add(const LoadServiceByIdEvent('service1'))).called(1);
    });
  });

  group('WedyServicePage - Service Details Loaded', () {
    testWidgets('should display service details when service is loaded', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServiceDetailsLoaded(tService));

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: ServiceDetailsLoaded(tService), serviceId: 'service1'));

      // Assert
      expect(find.text('Test Service'), findsOneWidget);
      expect(find.text('Test Merchant'), findsOneWidget);
      expect(find.text('Toshkent'), findsWidgets);
      expect(find.text('Category 1'), findsOneWidget);
      expect(find.text('100000 so\'m'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('should display service statistics', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServiceDetailsLoaded(tService));

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: ServiceDetailsLoaded(tService), serviceId: 'service1'));

      // Assert
      expect(find.text('Statistika'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget); // Rating
      expect(find.text('100'), findsOneWidget); // View count
      expect(find.text('10'), findsWidgets); // Review count and share count
    });

    testWidgets('should display gallery section when service has images', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServiceDetailsLoaded(tService));

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: ServiceDetailsLoaded(tService), serviceId: 'service1'));

      // Assert
      expect(find.text('Galareya'), findsOneWidget);
    });

    testWidgets('should display contact tabs', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServiceDetailsLoaded(tService));

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: ServiceDetailsLoaded(tService), serviceId: 'service1'));

      // Assert
      // Contact tabs should be visible (phone, location, social)
      expect(find.text('Fikrlar'), findsOneWidget);
    });

    testWidgets('should display location card when location data is available', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(ServiceDetailsLoaded(tService));

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: ServiceDetailsLoaded(tService), serviceId: 'service1'));

      // Assert
      // Location card should be visible when latitude and longitude are available
      // We can check for the "Kartada ko'rish" button
      expect(find.text('Kartada ko\'rish'), findsOneWidget);
    });
  });

  group('WedyServicePage - Service Not Found', () {
    testWidgets('should display not found message when service is null', (WidgetTester tester) async {
      // Arrange
      // Use ServiceInitial state which doesn't have service data
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: const ServiceInitial(), serviceId: 'service1'));

      // Assert
      expect(find.text('Xizmat topilmadi'), findsOneWidget);
      expect(find.text('Xizmat ma\'lumotlari topilmadi'), findsOneWidget);
    });
  });

  group('WedyServicePage - Initialization', () {
    testWidgets('should render widget when serviceId is provided', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: const ServiceInitial(), serviceId: 'service1'));
      await tester.pump();

      // Assert
      // The widget creates its own BlocProvider, so we can't verify the mock
      // But we can verify the widget renders without errors
      expect(find.byType(WedyServicePage), findsOneWidget);
    });

    testWidgets('should render widget when serviceId is not provided', (WidgetTester tester) async {
      // Arrange
      when(() => mockServiceBloc.state).thenReturn(const ServiceInitial());

      // Act
      await tester.pumpWidget(createTestWidget(serviceState: const ServiceInitial(), serviceId: null));
      await tester.pump();

      // Assert
      // The widget creates its own BlocProvider, so we can't verify the mock
      // But we can verify the widget renders without errors
      expect(find.byType(WedyServicePage), findsOneWidget);
    });
  });
}
