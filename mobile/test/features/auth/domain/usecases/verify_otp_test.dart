import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/entities/auth_tokens.dart';
import 'package:wedy/features/auth/domain/repositories/auth_repository.dart';
import 'package:wedy/features/auth/domain/usecases/verify_otp.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyOtp useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = VerifyOtp(mockRepository);
  });

  const tPhoneNumber = '901234567';
  const tOtpCode = '123456';
  final tAuthTokens = AuthTokens(
    accessToken: 'access_token',
    refreshToken: 'refresh_token',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
  );

  test('should verify OTP successfully and return tokens', () async {
    // Arrange
    when(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    ).thenAnswer((_) async => Right(tAuthTokens));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, otpCode: tOtpCode);

    // Assert
    expect(result, Right(tAuthTokens));
    verify(() => mockRepository.verifyOtp(phoneNumber: tPhoneNumber, otpCode: tOtpCode)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when phone number is empty', () async {
    // Act
    final result = await useCase(phoneNumber: '', otpCode: tOtpCode);

    // Assert
    expect(result, const Left(ValidationFailure('Phone number cannot be empty')));
    verifyNever(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    );
  });

  test('should return ValidationFailure when OTP code is empty', () async {
    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, otpCode: '');

    // Assert
    expect(result, const Left(ValidationFailure('OTP code cannot be empty')));
    verifyNever(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    );
  });

  test('should return ValidationFailure when OTP code is not 6 digits', () async {
    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, otpCode: '12345'); // 5 digits

    // Assert
    expect(result, const Left(ValidationFailure('OTP code must be 6 digits')));
    verifyNever(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    );
  });

  test('should return ValidationFailure when OTP code contains non-digits', () async {
    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, otpCode: '12345a');

    // Assert
    expect(result, const Left(ValidationFailure('OTP code must be 6 digits')));
    verifyNever(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    );
  });

  test('should return AuthFailure when repository returns authentication error', () async {
    // Arrange
    when(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    ).thenAnswer((_) async => const Left(AuthFailure('Invalid OTP')));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, otpCode: tOtpCode);

    // Assert
    expect(result, const Left(AuthFailure('Invalid OTP')));
    verify(() => mockRepository.verifyOtp(phoneNumber: tPhoneNumber, otpCode: tOtpCode)).called(1);
  });

  test('should accept valid 6-digit OTP codes', () async {
    // Arrange
    when(
      () => mockRepository.verifyOtp(
        phoneNumber: any(named: 'phoneNumber'),
        otpCode: any(named: 'otpCode'),
      ),
    ).thenAnswer((_) async => Right(tAuthTokens));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, otpCode: '000000');

    // Assert
    expect(result, Right(tAuthTokens));
    verify(() => mockRepository.verifyOtp(phoneNumber: tPhoneNumber, otpCode: '000000')).called(1);
  });
}
