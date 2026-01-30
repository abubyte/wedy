import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_avatar.dart';
import '../../domain/usecases/delete_avatar.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for profile management
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile _getProfileUseCase;
  final UpdateProfile _updateProfileUseCase;
  final UploadAvatar _uploadAvatarUseCase;
  final DeleteAvatar _deleteAvatarUseCase;

  ProfileBloc({
    required GetProfile getProfileUseCase,
    required UpdateProfile updateProfileUseCase,
    required UploadAvatar uploadAvatarUseCase,
    required DeleteAvatar deleteAvatarUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _uploadAvatarUseCase = uploadAvatarUseCase,
       _deleteAvatarUseCase = deleteAvatarUseCase,
       super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadAvatarEvent>(_onUploadAvatar);
    on<DeleteAvatarEvent>(_onDeleteAvatar);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await _getProfileUseCase();

    result.fold(
      (failure) => emit(ProfileError(failure.toUserMessage(entityName: 'Profile'))),
      (user) => emit(ProfileLoaded(user)),
    );
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await _updateProfileUseCase(
      name: event.name,
      phoneNumber: event.phoneNumber,
      otpCode: event.otpCode,
    );

    result.fold(
      (failure) => emit(ProfileError(failure.toUserMessage(entityName: 'Profile'))),
      (user) => emit(ProfileUpdated(user)),
    );
  }

  Future<void> _onUploadAvatar(UploadAvatarEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await _uploadAvatarUseCase(event.imagePath);

    await result.fold((failure) async => emit(ProfileError(failure.toUserMessage(entityName: 'Avatar'))), (
      avatarUrl,
    ) async {
      // Reload profile to get updated user data
      final profileResult = await _getProfileUseCase();
      profileResult.fold(
        (failure) => emit(ProfileError(failure.toUserMessage(entityName: 'Profile'))),
        (user) => emit(AvatarUploaded(avatarUrl: avatarUrl, user: user)),
      );
    });
  }

  Future<void> _onDeleteAvatar(DeleteAvatarEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await _deleteAvatarUseCase();

    await result.fold((failure) async => emit(ProfileError(failure.toUserMessage(entityName: 'Avatar'))), (_) async {
      // Reload profile to get updated user data
      final profileResult = await _getProfileUseCase();
      profileResult.fold(
        (failure) => emit(ProfileError(failure.toUserMessage(entityName: 'Profile'))),
        (user) => emit(AvatarDeleted(user: user)),
      );
    });
  }
}
