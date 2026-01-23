import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';
import 'package:wedy/features/service/domain/usecases/get_liked_services.dart';
import 'package:wedy/features/service/domain/usecases/get_service_by_id.dart';
import 'package:wedy/features/service/domain/usecases/get_services.dart';
import 'package:wedy/features/service/domain/usecases/interact_with_service.dart';
import 'package:wedy/features/service/domain/usecases/get_saved_services.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';

class MockGetServices extends Mock implements GetServices {}

class MockGetServiceById extends Mock implements GetServiceById {}

class MockInteractWithService extends Mock implements InteractWithService {}

class MockGetSavedServices extends Mock implements GetSavedServices {}

class MockGetLikedServices extends Mock implements GetLikedServices {}

void main() {
  late ServiceBloc bloc;
  late MockGetServices mockGetServices;
  late MockGetServiceById mockGetServiceById;
  late MockInteractWithService mockInteractWithService;
  late MockGetSavedServices mockGetSavedServices;
  late MockGetLikedServices mockGetLikedServices;

  setUpAll(() {
    registerFallbackValue(ServiceSearchFilters());
  });

  setUp(() {
    mockGetServices = MockGetServices();
    mockGetServiceById = MockGetServiceById();
    mockInteractWithService = MockInteractWithService();
    mockGetSavedServices = MockGetSavedServices();
    mockGetLikedServices = MockGetLikedServices();
    bloc = ServiceBloc(
      getServicesUseCase: mockGetServices,
      getServiceByIdUseCase: mockGetServiceById,
      interactWithServiceUseCase: mockInteractWithService,
      getSavedServicesUseCase: mockGetSavedServices,
      getLikedServicesUseCase: mockGetLikedServices,
    );
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

  final tInteractionResponse = ServiceInteractionResponse(
    success: true,
    message: 'Service liked successfully',
    newCount: 51,
  );

  group('ServiceBloc', () {
    test('initial state should be ServiceInitial', () {
      expect(bloc.state, const ServiceInitial());
    });

    group('LoadServicesEvent', () {
      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServicesLoaded] when services are loaded successfully',
        build: () {
          when(
            () => mockGetServices(
              featured: any(named: 'featured'),
              filters: any(named: 'filters'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Right(tPaginatedResponse));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadServicesEvent()),
        expect: () => [
          const ServiceLoading(),
          ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
        ],
        verify: (_) {
          verify(() => mockGetServices(featured: null, filters: null, page: 1, limit: 20)).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceError] when services load fails',
        build: () {
          when(
            () => mockGetServices(
              featured: any(named: 'featured'),
              filters: any(named: 'filters'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadServicesEvent()),
        expect: () => [
          const ServiceLoading(),
          const ServiceError('Network error. Please check your internet connection.'),
        ],
        verify: (_) {
          verify(() => mockGetServices(featured: null, filters: null, page: 1, limit: 20)).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServicesLoaded] when featured services are loaded',
        build: () {
          when(
            () => mockGetServices(
              featured: true,
              filters: any(named: 'filters'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Right(tPaginatedResponse));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadServicesEvent()),
        expect: () => [
          const ServiceLoading(),
          ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
        ],
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServicesLoaded] when services are loaded with filters',
        build: () {
          final filters = ServiceSearchFilters(query: 'test', categoryId: 1, locationRegion: 'Toshkent');
          when(
            () => mockGetServices(
              featured: any(named: 'featured'),
              filters: filters,
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Right(tPaginatedResponse));
          return bloc;
        },
        act: (bloc) {
          final filters = ServiceSearchFilters(query: 'test', categoryId: 1, locationRegion: 'Toshkent');
          bloc.add(LoadServicesEvent(filters: filters));
        },
        expect: () => [
          const ServiceLoading(),
          ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
        ],
      );
    });

    group('LoadMoreServicesEvent', () {
      blocTest<ServiceBloc, ServiceState>(
        'emits [ServicesLoaded] when more services are loaded successfully',
        build: () {
          when(
            () => mockGetServices(
              featured: any(named: 'featured'),
              filters: any(named: 'filters'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Right(tPaginatedResponse));
          return bloc;
        },
        seed: () => ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
        wait: const Duration(milliseconds: 100),
        act: (bloc) => bloc.add(const LoadMoreServicesEvent()),
        expect: () => [
          const ServiceLoading(),
          ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
          ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem, tServiceListItem]),
        ],
      );

      blocTest<ServiceBloc, ServiceState>(
        'does not emit when hasMore is false',
        build: () {
          final responseNoMore = PaginatedServiceResponse(
            services: [],
            total: 1,
            page: 1,
            limit: 20,
            hasMore: false,
            totalPages: 1,
          );
          when(
            () => mockGetServices(
              featured: any(named: 'featured'),
              filters: any(named: 'filters'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Right(responseNoMore));
          return bloc;
        },
        seed: () {
          final responseNoMore = PaginatedServiceResponse(
            services: [],
            total: 1,
            page: 1,
            limit: 20,
            hasMore: false,
            totalPages: 1,
          );
          return ServicesLoaded(currentPaginatedResponse: responseNoMore, paginatedServices: [tServiceListItem]);
        },
        act: (bloc) => bloc.add(const LoadMoreServicesEvent()),
        expect: () => [],
      );

      blocTest<ServiceBloc, ServiceState>(
        'does not emit when already loading',
        build: () => bloc,
        seed: () => const ServiceLoading(),
        act: (bloc) => bloc.add(const LoadMoreServicesEvent()),
        expect: () => [],
      );
    });

    group('LoadServiceByIdEvent', () {
      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceDetailsLoaded] when service is loaded successfully',
        build: () {
          when(() => mockGetServiceById('service1')).thenAnswer((_) async => Right(tService));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadServiceByIdEvent('service1')),
        expect: () => [const ServiceLoading(), ServicesLoaded(currentServiceDetails: tService)],
        verify: (_) {
          verify(() => mockGetServiceById('service1')).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceError] when service load fails',
        build: () {
          when(
            () => mockGetServiceById('service1'),
          ).thenAnswer((_) async => const Left(NotFoundFailure('Service not found')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadServiceByIdEvent('service1')),
        expect: () => [const ServiceLoading(), const ServiceError('Service not found.')],
        verify: (_) {
          verify(() => mockGetServiceById('service1')).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceError] when service load returns NetworkFailure',
        build: () {
          when(
            () => mockGetServiceById('service1'),
          ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadServiceByIdEvent('service1')),
        expect: () => [
          const ServiceLoading(),
          const ServiceError('Network error. Please check your internet connection.'),
        ],
      );
    });

    group('InteractWithServiceEvent', () {
      blocTest<ServiceBloc, ServiceState>(
        'emits [ServicesLoaded] with optimistic update then final state when like is successful',
        build: () {
          when(() => mockInteractWithService('service1', 'like')).thenAnswer((_) async => Right(tInteractionResponse));
          return bloc;
        },
        seed: () => ServicesLoaded(paginatedServices: [tServiceListItem]),
        act: (bloc) => bloc.add(const InteractWithServiceEvent(serviceId: 'service1', interactionType: 'like')),
        expect: () => [
          isA<ServicesLoaded>(), // Optimistic update
          isA<ServicesLoaded>(), // Final state with API response
        ],
        verify: (_) {
          verify(() => mockInteractWithService('service1', 'like')).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServicesLoaded] with optimistic update then final state when save is successful',
        build: () {
          final saveResponse = ServiceInteractionResponse(
            success: true,
            message: 'Service saved successfully',
            newCount: 26,
          );
          when(() => mockInteractWithService('service1', 'save')).thenAnswer((_) async => Right(saveResponse));
          return bloc;
        },
        seed: () => ServicesLoaded(paginatedServices: [tServiceListItem]),
        act: (bloc) => bloc.add(const InteractWithServiceEvent(serviceId: 'service1', interactionType: 'save')),
        expect: () => [
          isA<ServicesLoaded>(), // Optimistic update
          isA<ServicesLoaded>(), // Final state with API response
        ],
      );

      blocTest<ServiceBloc, ServiceState>(
        'reverts optimistic update and emits [ServiceError] when interaction fails',
        build: () {
          when(
            () => mockInteractWithService('service1', 'like'),
          ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
          return bloc;
        },
        seed: () => ServicesLoaded(paginatedServices: [tServiceListItem]),
        act: (bloc) => bloc.add(const InteractWithServiceEvent(serviceId: 'service1', interactionType: 'like')),
        expect: () => [
          isA<ServicesLoaded>(), // Optimistic update
          isA<ServicesLoaded>(), // Revert to previous state
          const ServiceError('Network error. Please check your internet connection.'),
        ],
        verify: (_) {
          verify(() => mockInteractWithService('service1', 'like')).called(1);
        },
      );
    });

    group('RefreshServicesEvent', () {
      blocTest<ServiceBloc, ServiceState>(
        'triggers LoadServicesEvent with current filters',
        build: () {
          when(
            () => mockGetServices(
              featured: any(named: 'featured'),
              filters: any(named: 'filters'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Right(tPaginatedResponse));
          return bloc;
        },
        seed: () => ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
        act: (bloc) => bloc.add(const RefreshServicesEvent()),
        expect: () => [
          const ServiceLoading(),
          ServicesLoaded(currentPaginatedResponse: tPaginatedResponse, paginatedServices: [tServiceListItem]),
        ],
      );
    });

    group('LoadSavedServicesEvent', () {
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

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, SavedServicesLoaded] when saved services are loaded successfully',
        build: () {
          when(() => mockGetSavedServices()).thenAnswer((_) async => Right(tSavedServices));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedServicesEvent()),
        expect: () => [const ServiceLoading(), ServicesLoaded(savedServices: tSavedServices)],
        verify: (_) {
          verify(() => mockGetSavedServices()).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, SavedServicesLoaded] with empty list when no saved services',
        build: () {
          when(() => mockGetSavedServices()).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedServicesEvent()),
        expect: () => [const ServiceLoading(), const ServicesLoaded(savedServices: [])],
        verify: (_) {
          verify(() => mockGetSavedServices()).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceError] when loading saved services fails',
        build: () {
          when(() => mockGetSavedServices()).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedServicesEvent()),
        expect: () => [
          const ServiceLoading(),
          const ServiceError('Network error. Please check your internet connection.'),
        ],
        verify: (_) {
          verify(() => mockGetSavedServices()).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceError] when server error occurs',
        build: () {
          when(() => mockGetSavedServices()).thenAnswer((_) async => const Left(ServerFailure('Server error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedServicesEvent()),
        expect: () => [const ServiceLoading(), const ServiceError('Server error. Please try again later.')],
        verify: (_) {
          verify(() => mockGetSavedServices()).called(1);
        },
      );

      blocTest<ServiceBloc, ServiceState>(
        'emits [ServiceLoading, ServiceError] when unauthorized',
        build: () {
          when(() => mockGetSavedServices()).thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedServicesEvent()),
        expect: () => [const ServiceLoading(), const ServiceError('Authentication failed. Please login again.')],
        verify: (_) {
          verify(() => mockGetSavedServices()).called(1);
        },
      );
    });
  });
}
