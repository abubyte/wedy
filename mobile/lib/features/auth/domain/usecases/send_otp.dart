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

    // Normalize phone number
    final normalized = _normalizePhoneNumber(phoneNumber);

    // Phone number format validation (Uzbekistan format: 9 digits)
    if (!_isValidUzbekPhoneNumber(normalized)) {
      return const Left(ValidationFailure('Invalid phone number format'));
    }

    // Call repository (data layer) with normalized number
    return await repository.sendOtp(normalized);
  }

  /// Normalize phone number to standard format (9 digits)
  String _normalizePhoneNumber(String phone) {
    // Remove any spaces, dashes, or non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // If it starts with country code 998, remove it
    if (cleaned.startsWith('998') && cleaned.length == 12) {
      return cleaned.substring(3);
    }

    // Return last 9 digits (in case of any extra digits)
    if (cleaned.length >= 9) {
      return cleaned.substring(cleaned.length - 9);
    }

    return cleaned;
  }

  bool _isValidUzbekPhoneNumber(String phone) {
    // Check if it's exactly 9 digits (Uzbekistan format)
    // Phone number should already be normalized at this point
    return RegExp(r'^\d{9}$').hasMatch(phone);
  }
}
