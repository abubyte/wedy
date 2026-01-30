import 'package:get_it/get_it.dart';
import 'package:wedy/features/service/domain/usecases/get_featured_services.dart';
import 'package:wedy/apps/client/pages/home/blocs/featured_services/featured_services_bloc.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/send_otp.dart';
import '../../features/auth/domain/usecases/verify_otp.dart';
import '../../features/auth/domain/usecases/register_user.dart';
import '../../features/auth/domain/usecases/refresh_token.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/domain/usecases/upload_avatar.dart';
import '../../features/profile/domain/usecases/delete_avatar.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/service/data/datasources/service_remote_datasource.dart';
import '../../features/service/data/repositories/service_repository_impl.dart';
import '../../features/service/domain/repositories/service_repository.dart';
import '../../features/service/domain/usecases/get_services.dart';
import '../../features/service/domain/usecases/get_service_by_id.dart';
import '../../features/service/domain/usecases/interact_with_service.dart';
import '../../features/service/domain/usecases/get_saved_services.dart';
import '../../features/service/domain/usecases/get_liked_services.dart';
import '../../features/service/domain/usecases/get_merchant_services.dart';
import '../../features/service/domain/usecases/create_merchant_service.dart';
import '../../features/service/domain/usecases/update_merchant_service.dart';
import '../../features/service/domain/usecases/delete_merchant_service.dart';
import '../../features/service/presentation/bloc/service_bloc.dart';
import '../../features/service/presentation/bloc/merchant_service_bloc.dart';
import '../../features/category/data/datasources/category_remote_datasource.dart';
import '../../features/category/data/repositories/category_repository_impl.dart';
import '../../features/category/domain/repositories/category_repository.dart';
import '../../features/category/domain/usecases/get_categories.dart';
import '../../features/category/presentation/bloc/category_bloc.dart';
import '../../features/reviews/data/datasources/review_remote_datasource.dart';
import '../../features/reviews/data/repositories/review_repository_impl.dart';
import '../../features/reviews/domain/repositories/review_repository.dart';
import '../../features/reviews/domain/usecases/get_reviews.dart';
import '../../features/reviews/domain/usecases/get_user_reviews.dart';
import '../../features/reviews/domain/usecases/create_review.dart';
import '../../features/reviews/domain/usecases/update_review.dart';
import '../../features/reviews/domain/usecases/delete_review.dart';
import '../../features/reviews/presentation/bloc/review_bloc.dart';
import '../../features/tariff/data/datasources/tariff_remote_datasource.dart';
import '../../features/tariff/data/repositories/tariff_repository_impl.dart';
import '../../features/tariff/domain/repositories/tariff_repository.dart';
import '../../features/tariff/domain/usecases/get_tariff_plans.dart';
import '../../features/tariff/domain/usecases/get_subscription.dart';
import '../../features/tariff/domain/usecases/create_tariff_payment.dart';
import '../../features/tariff/domain/usecases/activate_subscription.dart';
import '../../features/tariff/presentation/bloc/tariff_bloc.dart';
import '../../features/analytics/data/datasources/analytics_remote_datasource.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/analytics/domain/usecases/get_merchant_analytics.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/gallery/data/datasources/gallery_remote_datasource.dart';
import '../../features/gallery/data/repositories/gallery_repository_impl.dart';
import '../../features/gallery/domain/repositories/gallery_repository.dart';
import '../../features/gallery/domain/usecases/get_gallery_images.dart';
import '../../features/gallery/domain/usecases/add_gallery_image.dart';
import '../../features/gallery/domain/usecases/remove_gallery_image.dart';
import '../../features/gallery/presentation/bloc/gallery_bloc.dart';
import '../../features/featured_services/data/datasources/featured_services_remote_datasource.dart';
import '../../features/featured_services/data/repositories/featured_services_repository_impl.dart';
import '../../features/featured_services/domain/repositories/featured_services_repository.dart';
import '../../features/featured_services/domain/usecases/get_featured_services_tracking.dart';
import '../../features/featured_services/domain/usecases/create_monthly_featured_service.dart';
import '../../features/featured_services/domain/usecases/create_featured_payment.dart';
import '../../features/featured_services/presentation/bloc/featured_services_bloc.dart' as merchant_featured;

/// Service locator instance
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> init() async {
  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => createAuthRemoteDataSource());
  getIt.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSource());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt(), localDataSource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton(() => SendOtp(getIt()));
  getIt.registerLazySingleton(() => VerifyOtp(getIt()));
  getIt.registerLazySingleton(() => RegisterUser(getIt()));
  getIt.registerLazySingleton(() => RefreshToken(getIt()));

  // Profile data sources
  getIt.registerLazySingleton<ProfileRemoteDataSource>(() => createProfileRemoteDataSource());

  // Profile repositories
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: getIt(), localDataSource: getIt()),
  );

  // Profile use cases
  getIt.registerLazySingleton(() => GetProfile(getIt()));
  getIt.registerLazySingleton(() => UpdateProfile(getIt()));
  getIt.registerLazySingleton(() => UploadAvatar(getIt()));
  getIt.registerLazySingleton(() => DeleteAvatar(getIt()));

  // BLoC
  getIt.registerFactory(
    () => AuthBloc(
      sendOtpUseCase: getIt(),
      verifyOtpUseCase: getIt(),
      registerUserUseCase: getIt(),
      refreshTokenUseCase: getIt(),
      authRepository: getIt(),
      localDataSource: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ProfileBloc(
      getProfileUseCase: getIt(),
      updateProfileUseCase: getIt(),
      uploadAvatarUseCase: getIt(),
      deleteAvatarUseCase: getIt(),
    ),
  );

  // Home BLoCs
  getIt.registerFactory(() => FeaturedServicesBloc(getFeaturedServicesUseCase: getIt()));

  // Service data sources
  getIt.registerLazySingleton<ServiceRemoteDataSource>(() => createServiceRemoteDataSource());

  // Service repositories
  getIt.registerLazySingleton<ServiceRepository>(() => ServiceRepositoryImpl(remoteDataSource: getIt()));

  // Service use cases
  getIt.registerLazySingleton(() => GetServices(getIt()));
  getIt.registerLazySingleton(() => GetFeaturedServices(getIt()));
  getIt.registerLazySingleton(() => GetServiceById(getIt()));
  getIt.registerLazySingleton(() => InteractWithService(getIt()));
  getIt.registerLazySingleton(() => GetSavedServices(getIt()));
  getIt.registerLazySingleton(() => GetLikedServices(getIt()));

  // Merchant service use cases
  getIt.registerLazySingleton(() => GetMerchantServices(getIt()));
  getIt.registerLazySingleton(() => CreateMerchantService(getIt()));
  getIt.registerLazySingleton(() => UpdateMerchantService(getIt()));
  getIt.registerLazySingleton(() => DeleteMerchantService(getIt()));

  // Service BLoC - Singleton to sync liked/saved state across all pages
  getIt.registerLazySingleton(
    () => ServiceBloc(
      getServicesUseCase: getIt(),
      getServiceByIdUseCase: getIt(),
      interactWithServiceUseCase: getIt(),
      getSavedServicesUseCase: getIt(),
      getLikedServicesUseCase: getIt(),
    ),
  );

  // Merchant Service BLoC
  getIt.registerFactory(
    () => MerchantServiceBloc(
      getMerchantServices: getIt(),
      createMerchantService: getIt(),
      updateMerchantService: getIt(),
      deleteMerchantService: getIt(),
    ),
  );

  // Category data sources
  getIt.registerLazySingleton<CategoryRemoteDataSource>(() => createCategoryRemoteDataSource());

  // Category repositories
  getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(remoteDataSource: getIt()));

  // Category use cases
  getIt.registerLazySingleton(() => GetCategories(getIt()));

  // Category BLoC
  getIt.registerFactory(() => CategoryBloc(getCategoriesUseCase: getIt()));

  // Review data sources
  getIt.registerLazySingleton<ReviewRemoteDataSource>(() => createReviewRemoteDataSource());

  // Review repositories
  getIt.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(remoteDataSource: getIt()));

  // Review use cases
  getIt.registerLazySingleton(() => GetReviews(getIt()));
  getIt.registerLazySingleton(() => GetUserReviews(getIt()));
  getIt.registerLazySingleton(() => CreateReview(getIt()));
  getIt.registerLazySingleton(() => UpdateReview(getIt()));
  getIt.registerLazySingleton(() => DeleteReview(getIt()));

  // Review BLoC
  getIt.registerFactory(
    () => ReviewBloc(
      getReviewsUseCase: getIt(),
      getUserReviewsUseCase: getIt(),
      createReviewUseCase: getIt(),
      updateReviewUseCase: getIt(),
      deleteReviewUseCase: getIt(),
    ),
  );

  // Tariff data sources
  getIt.registerLazySingleton<TariffRemoteDataSource>(() => createTariffRemoteDataSource());

  // Tariff repositories
  getIt.registerLazySingleton<TariffRepository>(() => TariffRepositoryImpl(remoteDataSource: getIt()));

  // Tariff use cases
  getIt.registerLazySingleton(() => GetTariffPlans(getIt()));
  getIt.registerLazySingleton(() => GetSubscription(getIt()));
  getIt.registerLazySingleton(() => CreateTariffPayment(getIt()));
  getIt.registerLazySingleton(() => ActivateSubscription(getIt()));

  // Tariff BLoC
  getIt.registerFactory(
    () => TariffBloc(
      getTariffPlans: getIt(),
      getSubscription: getIt(),
      createTariffPayment: getIt(),
      activateSubscription: getIt(),
    ),
  );

  // Analytics data sources
  getIt.registerLazySingleton<AnalyticsRemoteDataSource>(() => createAnalyticsRemoteDataSource());

  // Analytics repositories
  getIt.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepositoryImpl(remoteDataSource: getIt()));

  // Analytics use cases
  getIt.registerLazySingleton(() => GetMerchantAnalytics(getIt()));

  // Analytics BLoC
  getIt.registerFactory(() => AnalyticsBloc(getMerchantAnalytics: getIt()));

  // Gallery data sources
  getIt.registerLazySingleton<GalleryRemoteDataSource>(() => createGalleryRemoteDataSource());

  // Gallery repositories
  getIt.registerLazySingleton<GalleryRepository>(() => GalleryRepositoryImpl(remoteDataSource: getIt()));

  // Gallery use cases
  getIt.registerLazySingleton(() => GetGalleryImages(getIt()));
  getIt.registerLazySingleton(() => AddGalleryImage(getIt()));
  getIt.registerLazySingleton(() => RemoveGalleryImage(getIt()));

  // Gallery BLoC
  getIt.registerFactory(
    () => GalleryBloc(getGalleryImages: getIt(), addGalleryImage: getIt(), removeGalleryImage: getIt()),
  );

  // Featured Services data sources
  getIt.registerLazySingleton<FeaturedServicesRemoteDataSource>(() => createFeaturedServicesRemoteDataSource());

  // Featured Services repositories
  getIt.registerLazySingleton<FeaturedServicesRepository>(
    () => FeaturedServicesRepositoryImpl(remoteDataSource: getIt()),
  );

  // Featured Services use cases
  getIt.registerLazySingleton(() => GetFeaturedServicesTracking(getIt()));
  getIt.registerLazySingleton(() => CreateMonthlyFeaturedService(getIt()));
  getIt.registerLazySingleton(() => CreateFeaturedPayment(getIt()));

  // Merchant Featured Services BLoC
  getIt.registerFactory(
    () => merchant_featured.FeaturedServicesBloc(
      getFeaturedServicesTracking: getIt(),
      createMonthlyFeaturedService: getIt(),
      createFeaturedPayment: getIt(),
    ),
  );
}
