import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:wedy/features/auth/domain/entities/auth_tokens.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/auth/domain/repositories/auth_repository.dart';
import 'package:wedy/features/auth/domain/usecases/refresh_token.dart';
import 'package:wedy/features/auth/domain/usecases/register_user.dart';
import 'package:wedy/features/auth/domain/usecases/send_otp.dart';
import 'package:wedy/features/auth/domain/usecases/verify_otp.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_state.dart';

class MockSendOtp extends Mock implements SendOtp {}

class MockVerifyOtp extends Mock implements VerifyOtp {}

class MockRegisterUser extends Mock implements RegisterUser {}

class MockRefreshToken extends Mock implements RefreshToken {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthBloc bloc;
  late MockSendOtp mockSendOtp;
  late MockVerifyOtp mockVerifyOtp;
  late MockRegisterUser mockRegisterUser;
  late MockRefreshToken mockRefreshToken;
  late MockAuthRepository mockAuthRepository;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(UserType.client);
  });

  setUp(() {
    mockSendOtp = MockSendOtp();
    mockVerifyOtp = MockVerifyOtp();
    mockRegisterUser = MockRegisterUser();
    mockRefreshToken = MockRefreshToken();
    mockAuthRepository = MockAuthRepository();
    mockLocalDataSource = MockAuthLocalDataSource();
    bloc = AuthBloc(
      sendOtpUseCase: mockSendOtp,
      verifyOtpUseCase: mockVerifyOtp,
      registerUserUseCase: mockRegisterUser,
      refreshTokenUseCase: mockRefreshToken,
      authRepository: mockAuthRepository,
      localDataSource: mockLocalDataSource,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tPhoneNumber = '901234567';
  const tOtpCode = '123456';
  const tName = 'John Doe';
  final tAuthTokens = AuthTokens(
    accessToken: 'access_token',
    refreshToken: 'refresh_token',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
  );
  final tUser = User(id: '1', phoneNumber: tPhoneNumber, name: tName, type: UserType.client, createdAt: DateTime.now());

  test('initial state should be AuthInitial', () {
    expect(bloc.state, const AuthInitial());
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, OtpSent] when SendOtpEvent succeeds',
    build: () {
      when(() => mockSendOtp(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) => bloc.add(const SendOtpEvent(tPhoneNumber)),
    expect: () => [const AuthLoading(), const OtpSent(tPhoneNumber)],
    verify: (_) {
      verify(() => mockSendOtp(tPhoneNumber)).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when SendOtpEvent fails',
    build: () {
      when(() => mockSendOtp(any())).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
      return bloc;
    },
    act: (bloc) => bloc.add(const SendOtpEvent(tPhoneNumber)),
    expect: () => [const AuthLoading(), const AuthError('Network error')],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, RegistrationRequired] when VerifyOtpEvent returns empty tokens (new user)',
    build: () {
      when(
        () => mockVerifyOtp(
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => const Right(AuthTokens(accessToken: '', refreshToken: '', expiresAt: null)));
      return bloc;
    },
    act: (bloc) => bloc.add(const VerifyOtpEvent(phoneNumber: tPhoneNumber, otpCode: tOtpCode)),
    expect: () => [const AuthLoading(), const RegistrationRequired(tPhoneNumber)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, OtpVerified, Authenticated] when VerifyOtpEvent returns tokens (existing user)',
    build: () {
      when(
        () => mockVerifyOtp(
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => Right(tAuthTokens));
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => Right(tUser));
      return bloc;
    },
    act: (bloc) => bloc.add(const VerifyOtpEvent(phoneNumber: tPhoneNumber, otpCode: tOtpCode)),
    expect: () => [const AuthLoading(), const OtpVerified(), Authenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when VerifyOtpEvent fails',
    build: () {
      when(
        () => mockVerifyOtp(
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => const Left(AuthFailure('Invalid OTP')));
      return bloc;
    },
    act: (bloc) => bloc.add(const VerifyOtpEvent(phoneNumber: tPhoneNumber, otpCode: tOtpCode)),
    expect: () => [const AuthLoading(), const AuthError('Invalid OTP')],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, RegistrationCompleted] when CompleteRegistrationEvent succeeds',
    build: () {
      when(
        () => mockRegisterUser(
          phoneNumber: any(named: 'phoneNumber'),
          name: any(named: 'name'),
          userType: any(named: 'userType'),
        ),
      ).thenAnswer((_) async => Right(tUser));
      return bloc;
    },
    act: (bloc) =>
        bloc.add(const CompleteRegistrationEvent(phoneNumber: tPhoneNumber, name: tName, userType: UserType.client)),
    expect: () => [const AuthLoading(), RegistrationCompleted(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when CompleteRegistrationEvent fails',
    build: () {
      when(
        () => mockRegisterUser(
          phoneNumber: any(named: 'phoneNumber'),
          name: any(named: 'name'),
          userType: any(named: 'userType'),
        ),
      ).thenAnswer((_) async => const Left(ValidationFailure('Name cannot be empty')));
      return bloc;
    },
    act: (bloc) =>
        bloc.add(const CompleteRegistrationEvent(phoneNumber: tPhoneNumber, name: tName, userType: UserType.client)),
    expect: () => [const AuthLoading(), const AuthError('Name cannot be empty')],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError, Unauthenticated] when RefreshTokenEvent fails',
    build: () {
      when(() => mockRefreshToken(any())).thenAnswer((_) async => const Left(AuthFailure('Invalid refresh token')));
      when(() => mockLocalDataSource.clearAuthData()).thenAnswer((_) async => {});
      return bloc;
    },
    act: (bloc) => bloc.add(const RefreshTokenEvent('refresh_token')),
    expect: () => [const AuthLoading(), const AuthError('Invalid refresh token'), const Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [Unauthenticated] when LogoutEvent is called',
    build: () {
      when(() => mockLocalDataSource.clearAuthData()).thenAnswer((_) async => {});
      return bloc;
    },
    act: (bloc) => bloc.add(const LogoutEvent()),
    expect: () => [const Unauthenticated()],
    verify: (_) {
      verify(() => mockLocalDataSource.clearAuthData()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits [Unauthenticated] when CheckAuthStatusEvent and user is not logged in',
    build: () {
      when(() => mockLocalDataSource.isLoggedIn()).thenAnswer((_) async => false);
      return bloc;
    },
    act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
    expect: () => [const Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [Authenticated] when CheckAuthStatusEvent and user is logged in',
    build: () {
      when(() => mockLocalDataSource.isLoggedIn()).thenAnswer((_) async => true);
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => Right(tUser));
      return bloc;
    },
    act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
    expect: () => [Authenticated(tUser)],
  );
}
