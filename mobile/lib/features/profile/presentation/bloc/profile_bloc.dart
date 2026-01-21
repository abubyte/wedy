import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_avatar.dart';
import '../../domain/usecases/delete_avatar.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for profile management
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfileUseCase;
  final UpdateProfile updateProfileUseCase;
  final UploadAvatar uploadAvatarUseCase;
  final DeleteAvatar deleteAvatarUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
  }) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadAvatarEvent>(_onUploadAvatar);
    on<DeleteAvatarEvent>(_onDeleteAvatar);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await getProfileUseCase();

    result.fold((failure) => emit(ProfileError(_getErrorMessage(failure))), (user) => emit(ProfileLoaded(user)));
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await updateProfileUseCase(name: event.name, phoneNumber: event.phoneNumber, otpCode: event.otpCode);

    result.fold((failure) => emit(ProfileError(_getErrorMessage(failure))), (user) => emit(ProfileUpdated(user)));
  }

  Future<void> _onUploadAvatar(UploadAvatarEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await uploadAvatarUseCase(event.imagePath);

    await result.fold((failure) async => emit(ProfileError(_getErrorMessage(failure))), (avatarUrl) async {
      // Reload profile to get updated user data
      final profileResult = await getProfileUseCase();
      profileResult.fold(
        (failure) => emit(ProfileError(_getErrorMessage(failure))),
        (user) => emit(AvatarUploaded(avatarUrl: avatarUrl, user: user)),
      );
    });
  }

  Future<void> _onDeleteAvatar(DeleteAvatarEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await deleteAvatarUseCase();

    await result.fold((failure) async => emit(ProfileError(_getErrorMessage(failure))), (_) async {
      // Reload profile to get updated user data
      final profileResult = await getProfileUseCase();
      profileResult.fold(
        (failure) => emit(ProfileError(_getErrorMessage(failure))),
        (user) => emit(AvatarDeleted(user: user)),
      );
    });
  }

  String _getErrorMessage(Failure failure) {
    return failure.message;
  }
}
