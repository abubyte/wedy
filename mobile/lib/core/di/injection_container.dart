import 'package:get_it/get_it.dart';
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
import '../../features/profile/presentation/bloc/profile_bloc.dart';

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
    () => ProfileBloc(getProfileUseCase: getIt(), updateProfileUseCase: getIt(), uploadAvatarUseCase: getIt()),
  );
}
