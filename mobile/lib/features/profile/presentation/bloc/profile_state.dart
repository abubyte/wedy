import '../../../auth/domain/entities/user.dart';

/// Profile states using Dart 3 sealed classes for exhaustiveness checking
sealed class ProfileState {
  const ProfileState();
}

/// Initial state
final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully
final class ProfileLoaded extends ProfileState {
  final User user;

  const ProfileLoaded(this.user);
}

/// Profile updated successfully
final class ProfileUpdated extends ProfileState {
  final User user;

  const ProfileUpdated(this.user);
}

/// Avatar uploaded successfully
final class AvatarUploaded extends ProfileState {
  final String avatarUrl;
  final User user;

  const AvatarUploaded({required this.avatarUrl, required this.user});
}

/// Avatar deleted successfully
final class AvatarDeleted extends ProfileState {
  final User user;

  const AvatarDeleted({required this.user});
}

/// Error state
final class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}
