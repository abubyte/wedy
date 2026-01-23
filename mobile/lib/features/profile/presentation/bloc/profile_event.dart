/// Profile events using Dart 3 sealed classes for exhaustiveness checking
sealed class ProfileEvent {
  const ProfileEvent();
}

/// Event to load user profile
final class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

/// Event to update user profile
final class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? phoneNumber;
  final String? otpCode;

  const UpdateProfileEvent({this.name, this.phoneNumber, this.otpCode});
}

/// Event to upload avatar
final class UploadAvatarEvent extends ProfileEvent {
  final String imagePath;

  const UploadAvatarEvent(this.imagePath);
}

/// Event to delete avatar
final class DeleteAvatarEvent extends ProfileEvent {
  const DeleteAvatarEvent();
}
