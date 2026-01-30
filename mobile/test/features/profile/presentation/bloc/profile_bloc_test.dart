import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/profile/domain/usecases/delete_avatar.dart';
import 'package:wedy/features/profile/domain/usecases/get_profile.dart';
import 'package:wedy/features/profile/domain/usecases/update_profile.dart';
import 'package:wedy/features/profile/domain/usecases/upload_avatar.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_event.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_state.dart';

class MockGetProfile extends Mock implements GetProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockUploadAvatar extends Mock implements UploadAvatar {}

class MockDeleteAvatar extends Mock implements DeleteAvatar {}

void main() {
  late ProfileBloc bloc;
  late MockGetProfile mockGetProfile;
  late MockUpdateProfile mockUpdateProfile;
  late MockUploadAvatar mockUploadAvatar;
  late MockDeleteAvatar mockDeleteAvatar;

  setUpAll(() {
    registerFallbackValue(User(id: '', phoneNumber: '', name: '', type: UserType.client, createdAt: DateTime.now()));
  });

  setUp(() {
    mockGetProfile = MockGetProfile();
    mockUpdateProfile = MockUpdateProfile();
    mockUploadAvatar = MockUploadAvatar();
    mockDeleteAvatar = MockDeleteAvatar();
    bloc = ProfileBloc(
      getProfileUseCase: mockGetProfile,
      updateProfileUseCase: mockUpdateProfile,
      uploadAvatarUseCase: mockUploadAvatar,
      deleteAvatarUseCase: mockDeleteAvatar,
    );
  });

  final tUser = User(
    id: '1',
    phoneNumber: '901234567',
    name: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    type: UserType.client,
    createdAt: DateTime.now(),
  );

  group('ProfileBloc', () {
    test('initial state should be ProfileInitial', () {
      expect(bloc.state, const ProfileInitial());
    });

    group('LoadProfileEvent', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when profile is loaded successfully',
        build: () {
          when(() => mockGetProfile()).thenAnswer((_) async => Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProfileEvent()),
        expect: () => [const ProfileLoading(), ProfileLoaded(tUser)],
        verify: (_) {
          verify(() => mockGetProfile()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when profile load fails',
        build: () {
          when(() => mockGetProfile()).thenAnswer((_) async => const Left(NetworkFailure('Network error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProfileEvent()),
        expect: () => [const ProfileLoading(), const ProfileError('Network error')],
        verify: (_) {
          verify(() => mockGetProfile()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when profile load returns AuthFailure',
        build: () {
          when(() => mockGetProfile()).thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProfileEvent()),
        expect: () => [const ProfileLoading(), const ProfileError('Unauthorized')],
      );
    });

    group('UpdateProfileEvent', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileUpdated] when profile is updated successfully',
        build: () {
          const tNewName = 'Jane Doe';
          final tUpdatedUser = User(
            id: tUser.id,
            phoneNumber: tUser.phoneNumber,
            name: tNewName,
            avatarUrl: tUser.avatarUrl,
            type: tUser.type,
            createdAt: tUser.createdAt,
          );
          when(() => mockUpdateProfile(name: tNewName, phoneNumber: null)).thenAnswer((_) async => Right(tUpdatedUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateProfileEvent(name: 'Jane Doe', phoneNumber: null)),
        expect: () => [const ProfileLoading(), isA<ProfileUpdated>()],
        verify: (_) {
          verify(() => mockUpdateProfile(name: 'Jane Doe', phoneNumber: null)).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when profile update fails',
        build: () {
          when(
            () => mockUpdateProfile(
              name: any(named: 'name'),
              phoneNumber: any(named: 'phoneNumber'),
            ),
          ).thenAnswer((_) async => const Left(ValidationFailure('Name is too short')));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateProfileEvent(name: 'A', phoneNumber: null)),
        expect: () => [const ProfileLoading(), const ProfileError('Name is too short')],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileUpdated] when phone number is updated',
        build: () {
          const tNewPhone = '998765432';
          final tUpdatedUser = User(
            id: tUser.id,
            phoneNumber: tNewPhone,
            name: tUser.name,
            avatarUrl: tUser.avatarUrl,
            type: tUser.type,
            createdAt: tUser.createdAt,
          );
          when(
            () => mockUpdateProfile(name: null, phoneNumber: tNewPhone),
          ).thenAnswer((_) async => Right(tUpdatedUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateProfileEvent(name: null, phoneNumber: '998765432')),
        expect: () => [const ProfileLoading(), isA<ProfileUpdated>()],
      );
    });

    group('UploadAvatarEvent', () {
      const tImagePath = '/path/to/image.jpg';
      const tAvatarUrl = 'https://example.com/new-avatar.jpg';

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, AvatarUploaded] when avatar is uploaded successfully',
        build: () {
          when(() => mockUploadAvatar(tImagePath)).thenAnswer((_) async => const Right(tAvatarUrl));
          when(() => mockGetProfile()).thenAnswer((_) async => Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const UploadAvatarEvent(tImagePath)),
        expect: () => [const ProfileLoading(), AvatarUploaded(avatarUrl: tAvatarUrl, user: tUser)],
        verify: (_) {
          verify(() => mockUploadAvatar(tImagePath)).called(1);
          verify(() => mockGetProfile()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when avatar upload fails',
        build: () {
          when(() => mockUploadAvatar(tImagePath)).thenAnswer((_) async => const Left(NetworkFailure('Upload failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(const UploadAvatarEvent(tImagePath)),
        expect: () => [const ProfileLoading(), const ProfileError('Upload failed')],
        verify: (_) {
          verify(() => mockUploadAvatar(tImagePath)).called(1);
          verifyNever(() => mockGetProfile());
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when profile reload fails after upload',
        build: () {
          when(() => mockUploadAvatar(tImagePath)).thenAnswer((_) async => const Right(tAvatarUrl));
          when(() => mockGetProfile()).thenAnswer((_) async => const Left(NetworkFailure('Failed to reload profile')));
          return bloc;
        },
        act: (bloc) => bloc.add(const UploadAvatarEvent(tImagePath)),
        expect: () => [const ProfileLoading(), const ProfileError('Failed to reload profile')],
        verify: (_) {
          verify(() => mockUploadAvatar(tImagePath)).called(1);
          verify(() => mockGetProfile()).called(1);
        },
      );
    });
  });
}
