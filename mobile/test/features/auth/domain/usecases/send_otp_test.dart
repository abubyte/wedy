import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/repositories/auth_repository.dart';
import 'package:wedy/features/auth/domain/usecases/send_otp.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendOtp useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendOtp(mockRepository);
  });

  const tPhoneNumber = '901234567';

  test('should send OTP successfully', () async {
    // Arrange
    when(() => mockRepository.sendOtp(any())).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tPhoneNumber);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.sendOtp(tPhoneNumber)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when phone number is empty', () async {
    // Act
    final result = await useCase('');

    // Assert
    expect(result, const Left(ValidationFailure('Phone number cannot be empty')));
    verifyNever(() => mockRepository.sendOtp(any()));
  });

  test('should return ValidationFailure when phone number format is invalid', () async {
    // Act - phone number with less than 9 digits
    final result = await useCase('12345'); // Invalid: not 9 digits

    // Assert
    expect(result, const Left(ValidationFailure('Invalid phone number format')));
    verifyNever(() => mockRepository.sendOtp(any()));
  });

  test('should accept phone number with spaces (validation passes and normalizes)', () async {
    // Arrange
    when(() => mockRepository.sendOtp(any())).thenAnswer((_) async => const Right(null));

    // Act - validation removes spaces and normalizes
    final result = await useCase('90 123 4567'); // Has spaces but will be normalized

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.sendOtp('901234567')).called(1); // Normalized to 9 digits
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(() => mockRepository.sendOtp(any())).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(tPhoneNumber);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.sendOtp(tPhoneNumber)).called(1);
  });

  test('should accept valid phone numbers starting with 9', () async {
    // Arrange
    when(() => mockRepository.sendOtp(any())).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase('912345678');

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.sendOtp('912345678')).called(1);
  });

  test('should accept any 9-digit phone number', () async {
    // Arrange
    when(() => mockRepository.sendOtp(any())).thenAnswer((_) async => const Right(null));

    // Act - phone number starting with 2 (like user's input)
    final result = await useCase('200003190');

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.sendOtp('200003190')).called(1);
  });

  test('should normalize phone number with country code', () async {
    // Arrange
    when(() => mockRepository.sendOtp(any())).thenAnswer((_) async => const Right(null));

    // Act - phone number with country code 998
    final result = await useCase('998901234567');

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.sendOtp('901234567')).called(1); // Country code removed
  });
}
