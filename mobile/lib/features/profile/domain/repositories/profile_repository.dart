import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Repository interface for profile management
abstract class ProfileRepository {
  /// Get current user profile
  Future<Either<Failure, User>> getProfile();

  /// Update user profile (name and/or phone number)
  Future<Either<Failure, User>> updateProfile({String? name, String? phoneNumber});

  /// Upload user avatar
  Future<Either<Failure, String>> uploadAvatar(String imagePath);
}
