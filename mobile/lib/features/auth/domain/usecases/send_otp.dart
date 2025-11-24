import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for sending OTP to a phone number
class SendOtp {
  final AuthRepository repository;

  SendOtp(this.repository);

  /// Execute the use case
  Future<Either<Failure, void>> call(String phoneNumber) async {
    // Business logic validation
    if (phoneNumber.isEmpty) {
      return const Left(ValidationFailure('Phone number cannot be empty'));
    }

    // Phone number format validation (Uzbekistan format: 9XXXXXXXXX)
    if (!_isValidUzbekPhoneNumber(phoneNumber)) {
      return const Left(ValidationFailure('Invalid phone number format'));
    }

    // Call repository (data layer)
    return await repository.sendOtp(phoneNumber);
  }

  bool _isValidUzbekPhoneNumber(String phone) {
    // Remove any spaces or dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    // Check if it's 9 digits starting with 9
    return RegExp(r'^9\d{8}$').hasMatch(cleaned);
  }
}
