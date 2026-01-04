import 'package:equatable/equatable.dart';

/// Base class for profile events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile
class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

/// Event to update user profile
class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? phoneNumber;
  final String? otpCode;

  const UpdateProfileEvent({this.name, this.phoneNumber, this.otpCode});

  @override
  List<Object?> get props => [name, phoneNumber, otpCode];
}

/// Event to upload avatar
class UploadAvatarEvent extends ProfileEvent {
  final String imagePath;

  const UploadAvatarEvent(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}
