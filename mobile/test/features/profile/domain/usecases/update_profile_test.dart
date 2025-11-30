import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/profile/domain/repositories/profile_repository.dart';
import 'package:wedy/features/profile/domain/usecases/update_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late UpdateProfile useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfile(mockRepository);
  });

  final tUser = User(
    id: '1',
    phoneNumber: '901234567',
    name: 'John Doe',
    type: UserType.client,
    createdAt: DateTime.now(),
  );

  test('should update profile with name successfully', () async {
    // Arrange
    const tNewName = 'Jane Doe';
    final tUpdatedUser = User(
      id: tUser.id,
      phoneNumber: tUser.phoneNumber,
      name: tNewName,
      type: tUser.type,
      createdAt: tUser.createdAt,
    );
    when(
      () => mockRepository.updateProfile(name: tNewName, phoneNumber: null),
    ).thenAnswer((_) async => Right(tUpdatedUser));

    // Act
    final result = await useCase(name: tNewName, phoneNumber: null);

    // Assert
    expect(result, Right(tUpdatedUser));
    verify(() => mockRepository.updateProfile(name: tNewName, phoneNumber: null)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should update profile with phone number successfully', () async {
    // Arrange
    const tNewPhone = '998765432';
    final tUpdatedUser = User(
      id: tUser.id,
      phoneNumber: tNewPhone,
      name: tUser.name,
      type: tUser.type,
      createdAt: tUser.createdAt,
    );
    when(
      () => mockRepository.updateProfile(name: null, phoneNumber: tNewPhone),
    ).thenAnswer((_) async => Right(tUpdatedUser));

    // Act
    final result = await useCase(name: null, phoneNumber: tNewPhone);

    // Assert
    expect(result, Right(tUpdatedUser));
    verify(() => mockRepository.updateProfile(name: null, phoneNumber: tNewPhone)).called(1);
  });

  test('should update profile with both name and phone number successfully', () async {
    // Arrange
    const tNewName = 'Jane Doe';
    const tNewPhone = '998765432';
    final tUpdatedUser = User(
      id: tUser.id,
      phoneNumber: tNewPhone,
      name: tNewName,
      type: tUser.type,
      createdAt: tUser.createdAt,
    );
    when(
      () => mockRepository.updateProfile(name: tNewName, phoneNumber: tNewPhone),
    ).thenAnswer((_) async => Right(tUpdatedUser));

    // Act
    final result = await useCase(name: tNewName, phoneNumber: tNewPhone);

    // Assert
    expect(result, Right(tUpdatedUser));
    verify(() => mockRepository.updateProfile(name: tNewName, phoneNumber: tNewPhone)).called(1);
  });

  test('should allow both name and phoneNumber to be null (validation happens in repository)', () async {
    // Arrange - The use case doesn't validate that at least one field is provided
    // This validation should happen at the repository/API level
    when(() => mockRepository.updateProfile(name: null, phoneNumber: null)).thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase(name: null, phoneNumber: null);

    // Assert
    expect(result, Right(tUser));
    verify(() => mockRepository.updateProfile(name: null, phoneNumber: null)).called(1);
  });

  test('should return ValidationFailure when name is empty', () async {
    // Act
    final result = await useCase(name: '', phoneNumber: null);

    // Assert
    expect(result, const Left(ValidationFailure('Name cannot be empty')));
    verifyNever(
      () => mockRepository.updateProfile(
        name: any(named: 'name'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    );
  });

  test('should return ValidationFailure when name is too short', () async {
    // Act
    final result = await useCase(name: 'A', phoneNumber: null);

    // Assert
    expect(result, const Left(ValidationFailure('Name must be at least 2 characters')));
    verifyNever(
      () => mockRepository.updateProfile(
        name: any(named: 'name'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    );
  });

  test('should return ValidationFailure when name is too long', () async {
    // Act
    final longName = 'A' * 101; // 101 characters
    final result = await useCase(name: longName, phoneNumber: null);

    // Assert
    expect(result, const Left(ValidationFailure('Name must be less than 100 characters')));
    verifyNever(
      () => mockRepository.updateProfile(
        name: any(named: 'name'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    );
  });

  test('should trim whitespace from name', () async {
    // Arrange
    const tNameWithSpaces = '  Jane Doe  ';
    const tTrimmedName = 'Jane Doe';
    final tUpdatedUser = User(
      id: tUser.id,
      phoneNumber: tUser.phoneNumber,
      name: tTrimmedName,
      type: tUser.type,
      createdAt: tUser.createdAt,
    );
    when(
      () => mockRepository.updateProfile(name: tTrimmedName, phoneNumber: null),
    ).thenAnswer((_) async => Right(tUpdatedUser));

    // Act
    final result = await useCase(name: tNameWithSpaces, phoneNumber: null);

    // Assert
    expect(result, Right(tUpdatedUser));
    verify(() => mockRepository.updateProfile(name: tTrimmedName, phoneNumber: null)).called(1);
  });

  test('should return ValidationFailure when phone number is empty', () async {
    // Act
    final result = await useCase(name: null, phoneNumber: '');

    // Assert
    expect(result, const Left(ValidationFailure('Phone number cannot be empty')));
    verifyNever(
      () => mockRepository.updateProfile(
        name: any(named: 'name'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    );
  });

  test('should return NetworkFailure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.updateProfile(name: 'John', phoneNumber: null),
    ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

    // Act
    final result = await useCase(name: 'John', phoneNumber: null);

    // Assert
    expect(result, const Left(NetworkFailure('Network error')));
    verify(() => mockRepository.updateProfile(name: 'John', phoneNumber: null)).called(1);
  });

  test('should return ValidationFailure when phone number is already taken', () async {
    // Arrange
    when(
      () => mockRepository.updateProfile(name: null, phoneNumber: '998765432'),
    ).thenAnswer((_) async => const Left(ValidationFailure('Phone number already taken')));

    // Act
    final result = await useCase(name: null, phoneNumber: '998765432');

    // Assert
    expect(result, const Left(ValidationFailure('Phone number already taken')));
    verify(() => mockRepository.updateProfile(name: null, phoneNumber: '998765432')).called(1);
  });
}
