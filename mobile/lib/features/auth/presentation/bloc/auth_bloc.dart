import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/refresh_token.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for authentication
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp sendOtpUseCase;
  final VerifyOtp verifyOtpUseCase;
  final RegisterUser registerUserUseCase;
  final RefreshToken refreshTokenUseCase;
  final AuthRepository authRepository;
  final AuthLocalDataSource localDataSource;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.registerUserUseCase,
    required this.refreshTokenUseCase,
    required this.authRepository,
    required this.localDataSource,
  }) : super(const AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CompleteRegistrationEvent>(_onCompleteRegistration);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await sendOtpUseCase(event.phoneNumber);

    result.fold((failure) => emit(AuthError(_getErrorMessage(failure))), (_) => emit(OtpSent(event.phoneNumber)));
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await verifyOtpUseCase(phoneNumber: event.phoneNumber, otpCode: event.otpCode);

    await result.fold((failure) async => emit(AuthError(_getErrorMessage(failure))), (tokens) async {
      // Check if tokens are empty (new user)
      if (tokens.accessToken.isEmpty) {
        emit(RegistrationRequired(event.phoneNumber));
      } else {
        // Existing user - tokens are saved, now fetch user profile and emit Authenticated
        await _fetchUserProfile(emit);
      }
    });
  }

  Future<void> _onCompleteRegistration(CompleteRegistrationEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await registerUserUseCase(
      phoneNumber: event.phoneNumber,
      name: event.name,
      userType: event.userType,
    );

    await result.fold((failure) async => emit(AuthError(_getErrorMessage(failure))), (_) async {
      // Registration completed - tokens are saved, now fetch user profile and emit Authenticated
      await _fetchUserProfile(emit);
    });
  }

  Future<void> _onRefreshToken(RefreshTokenEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await refreshTokenUseCase(event.refreshToken);

    await result.fold(
      (failure) async {
        emit(AuthError(_getErrorMessage(failure)));
        emit(const Unauthenticated());
      },
      (_) async {
        // Token refreshed successfully - fetch user profile
        await _fetchUserProfile(emit);
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await localDataSource.clearAuthData();
    emit(const Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    // Check if access token exists (more reliable than isLoggedIn flag)
    final accessToken = await localDataSource.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      // No access token - user is not logged in
      emit(const Unauthenticated());
      return;
    }

    // We have an access token - try to fetch profile
    // The auth interceptor will handle token refresh automatically if token is expired
    final result = await authRepository.getProfile();

    await result.fold(
      (failure) async {
        // Profile fetch failed - check if tokens were cleared by interceptor
        // (interceptor clears tokens if refresh fails)
        final remainingAccessToken = await localDataSource.getAccessToken();
        final remainingRefreshToken = await localDataSource.getRefreshToken();

        if (remainingAccessToken == null || remainingAccessToken.isEmpty) {
          // Tokens were cleared (likely by interceptor after failed refresh)
          // User is not authenticated
          emit(const Unauthenticated());
          return;
        }

        // Tokens still exist but profile fetch failed - try manual refresh
        if (remainingRefreshToken != null && remainingRefreshToken.isNotEmpty) {
          final refreshResult = await refreshTokenUseCase(remainingRefreshToken);

          await refreshResult.fold(
            (refreshFailure) async {
              // Refresh failed - clear auth data and emit unauthenticated
              await localDataSource.clearAuthData();
              emit(const Unauthenticated());
            },
            (_) async {
              // Token refreshed successfully - fetch user profile again
              await _fetchUserProfile(emit);
            },
          );
        } else {
          // No refresh token - clear auth data and emit unauthenticated
          await localDataSource.clearAuthData();
          emit(const Unauthenticated());
        }
      },
      (user) {
        // Profile fetched successfully - check user type if merchant app
        if (AppConfig.instance.appType == AppType.merchant) {
          if (user.type != UserType.merchant) {
            // User is not a merchant - clear auth data and show error
            localDataSource.clearAuthData();
            emit(const AuthError('Bu telefon raqam client akkaunt bilan ro\'yxatdan o\'tgan. Merchant akkaunt kerak.'));
            return;
          }
        }
        // User type is valid - user is authenticated
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _fetchUserProfile(Emitter<AuthState> emit) async {
    final result = await authRepository.getProfile();

    result.fold(
      (failure) {
        // If profile fetch fails, clear auth data and emit unauthenticated
        localDataSource.clearAuthData();
        emit(const Unauthenticated());
      },
      (user) {
        // If this is merchant app, verify user is a merchant
        if (AppConfig.instance.appType == AppType.merchant) {
          if (user.type != UserType.merchant) {
            // User is not a merchant - clear auth data and show error
            localDataSource.clearAuthData();
            emit(const AuthError('Bu telefon raqam client akkaunt bilan ro\'yxatdan o\'tgan. Merchant akkaunt kerak.'));
            return;
          }
        }
        // User type is valid - emit authenticated
        emit(Authenticated(user));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return failure.message;
  }
}
