import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/auth/domain/repositories/auth_repository.dart';
import 'package:wedy/features/auth/domain/usecases/register_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUser useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(UserType.client);
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUser(mockRepository);
  });

  const tPhoneNumber = '901234567';
  const tName = 'John Doe';
  const tUserType = UserType.client;
  final tUser = User(id: '1', phoneNumber: tPhoneNumber, name: tName, type: tUserType, createdAt: DateTime.now());

  test('should complete registration successfully', () async {
    // Arrange
    when(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    ).thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, name: tName, userType: tUserType);

    // Assert
    expect(result, Right(tUser));
    verify(
      () => mockRepository.completeRegistration(phoneNumber: tPhoneNumber, name: tName.trim(), userType: tUserType),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when phone number is empty', () async {
    // Act
    final result = await useCase(phoneNumber: '', name: tName, userType: tUserType);

    // Assert
    expect(result, const Left(ValidationFailure('Phone number cannot be empty')));
    verifyNever(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    );
  });

  test('should return ValidationFailure when name is empty', () async {
    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, name: '', userType: tUserType);

    // Assert
    expect(result, const Left(ValidationFailure('Name cannot be empty')));
    verifyNever(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    );
  });

  test('should return ValidationFailure when name is too short', () async {
    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, name: 'A', userType: tUserType);

    // Assert
    expect(result, const Left(ValidationFailure('Name must be at least 2 characters')));
    verifyNever(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    );
  });

  test('should return ValidationFailure when name is too long', () async {
    // Act
    final longName = 'A' * 101; // 101 characters
    final result = await useCase(phoneNumber: tPhoneNumber, name: longName, userType: tUserType);

    // Assert
    expect(result, const Left(ValidationFailure('Name must be less than 100 characters')));
    verifyNever(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    );
  });

  test('should trim whitespace from name', () async {
    // Arrange
    when(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    ).thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, name: '  John Doe  ', userType: tUserType);

    // Assert
    expect(result, Right(tUser));
    verify(
      () => mockRepository.completeRegistration(
        phoneNumber: tPhoneNumber,
        name: 'John Doe', // Trimmed
        userType: tUserType,
      ),
    ).called(1);
  });

  test('should work with merchant user type', () async {
    // Arrange
    when(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    ).thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, name: tName, userType: UserType.merchant);

    // Assert
    expect(result, Right(tUser));
    verify(
      () => mockRepository.completeRegistration(phoneNumber: tPhoneNumber, name: tName, userType: UserType.merchant),
    ).called(1);
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.completeRegistration(
        phoneNumber: any(named: 'phoneNumber'),
        name: any(named: 'name'),
        userType: any(named: 'userType'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(phoneNumber: tPhoneNumber, name: tName, userType: tUserType);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(
      () => mockRepository.completeRegistration(phoneNumber: tPhoneNumber, name: tName, userType: tUserType),
    ).called(1);
  });
}
