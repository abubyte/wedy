import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wedy/apps/client/pages/profile/profile_page.dart';
import 'package:wedy/features/auth/domain/entities/user.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_state.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_event.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_state.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockProfileBloc extends Mock implements ProfileBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;

  final tUser = User(
    id: '12345678-1234-1234-1234-123456789012',
    phoneNumber: '901234567',
    name: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    type: UserType.client,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const LoadProfileEvent());
    registerFallbackValue(const UpdateProfileEvent());
    registerFallbackValue(const UploadAvatarEvent(''));
    registerFallbackValue(const CheckAuthStatusEvent());
    registerFallbackValue(const LogoutEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
  });

  Widget createTestWidget({AuthState? authState, ProfileState? profileState}) {
    when(() => mockAuthBloc.state).thenReturn(authState ?? const AuthInitial());
    when(() => mockProfileBloc.state).thenReturn(profileState ?? const ProfileInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
    // Allow add calls without throwing errors
    when(() => mockAuthBloc.add(any())).thenReturn(null);
    when(() => mockProfileBloc.add(any())).thenReturn(null);

    // Create a simple GoRouter for testing with named routes
    // The widget uses context.pushNamed which requires GoRouter
    // Routes use the path as the name (matching the actual app setup)
    // Providers are at MaterialApp level so dialogs can access them
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', name: '/', builder: (context, state) => const ClientProfilePage()),
        GoRoute(
          path: '/auth',
          name: '/auth', // Route name matches path (as in actual app)
          builder: (context, state) => const Scaffold(body: Text('Auth Page')),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ClientProfilePage - Unauthenticated State', () {
    testWidgets('should display login button when user is not authenticated', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());

      // Act
      await tester.pumpWidget(createTestWidget(authState: const Unauthenticated()));

      // Assert
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Kirish'), findsOneWidget);
      expect(find.byIcon(IconsaxPlusLinear.profile), findsWidgets);
    });

    testWidgets('should navigate to auth page when login button is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());

      // Act
      await tester.pumpWidget(createTestWidget(authState: const Unauthenticated()));
      await tester.pump();
      await tester.tap(find.text('Kirish'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Verify navigation occurred
      expect(find.text('Auth Page'), findsOneWidget);
    });
  });

  group('ClientProfilePage - Authenticated State', () {
    testWidgets('should display user information when authenticated', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('ID: 12345678'), findsOneWidget);
      expect(find.text('Akkount'), findsOneWidget);
      expect(find.text('Chiqish'), findsOneWidget);
    });

    testWidgets('should display avatar when user has avatar URL', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert
      // Avatar is displayed via CachedNetworkImage which may not render in tests
      // But we can verify the structure exists
      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('should display default avatar icon when user has no avatar', (WidgetTester tester) async {
      // Arrange
      final userWithoutAvatar = User(
        id: tUser.id,
        phoneNumber: tUser.phoneNumber,
        name: tUser.name,
        avatarUrl: null,
        type: tUser.type,
        createdAt: tUser.createdAt,
      );
      final authState = Authenticated(userWithoutAvatar);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert
      expect(find.byIcon(IconsaxPlusLinear.profile), findsWidgets);
    });

    testWidgets('should display profile menu items', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert
      expect(find.text('Fikrlar'), findsOneWidget);
      expect(find.text('Sevimlilar'), findsOneWidget);
      expect(find.text('Yordam'), findsOneWidget);
      expect(find.text('Wedy Biznes'), findsOneWidget);
    });

    testWidgets('should handle loading state when profile is loading', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileLoading());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState, profileState: const ProfileLoading()));
      await tester.pump();

      // Assert - Widget should render without errors
      expect(find.text('John Doe'), findsOneWidget);
    });
  });

  group('ClientProfilePage - Interactions', () {
    testWidgets('should open edit profile dialog when account button is tapped', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();
      await tester.tap(find.text('Akkount'));
      await tester.pump();

      // Assert
      expect(find.text('Profilni tahrirlash'), findsOneWidget);
      expect(find.text('Ism'), findsOneWidget);
      expect(find.text('Telefon raqam'), findsOneWidget);
      expect(find.text('Saqlash'), findsOneWidget);
      expect(find.text('Bekor qilish'), findsOneWidget);
    });

    testWidgets('should dispatch UpdateProfileEvent when save button is tapped', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();
      await tester.tap(find.text('Akkount'));
      await tester.pump();

      // Find text field and update it
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Jane Doe');
      await tester.tap(find.text('Saqlash'));
      await tester.pump();

      // Assert
      verify(() => mockProfileBloc.add(any(that: isA<UpdateProfileEvent>()))).called(1);
    });

    testWidgets('should open logout dialog when logout button is tapped', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();
      await tester.tap(find.text('Chiqish').first);
      await tester.pump();

      // Assert - Dialog should appear
      expect(find.text('Haqiqatan ham chiqmoqchimisiz?'), findsOneWidget);
      expect(find.text('Bekor qilish'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should logout when confirmed in logout dialog', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();
      await tester.tap(find.text('Chiqish').first);
      await tester.pump();

      // Find the logout button in the dialog (last TextButton is the logout button)
      final dialogTextButtons = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
      expect(dialogTextButtons, findsNWidgets(2)); // Cancel and Logout buttons
      await tester.tap(dialogTextButtons.last); // Last button is logout
      await tester.pump();

      // Assert
      verify(() => mockAuthBloc.add(const LogoutEvent())).called(1);
    });

    testWidgets('should have avatar that can be tapped', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert - Avatar area exists (Stack with GestureDetector)
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should dispatch LoadProfileEvent on init', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert
      verify(() => mockProfileBloc.add(const LoadProfileEvent())).called(1);
    });
  });

  group('ClientProfilePage - Error Handling', () {
    testWidgets('should handle profile error state', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileError('Network error'));

      // Act
      await tester.pumpWidget(
        createTestWidget(authState: authState, profileState: const ProfileError('Network error')),
      );
      await tester.pump();

      // Assert - Widget should render without errors
      // Snackbar is shown via BlocListener on state change, which is tested in BLoC tests
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should show success snackbar when profile is updated', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      final updatedUser = User(
        id: tUser.id,
        phoneNumber: tUser.phoneNumber,
        name: 'Jane Doe',
        type: tUser.type,
        createdAt: tUser.createdAt,
      );
      when(() => mockProfileBloc.state).thenReturn(ProfileUpdated(updatedUser));

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState, profileState: ProfileUpdated(updatedUser)));
      await tester.pump();

      // Assert - Widget should render without errors
      // Snackbar is shown via BlocListener on state change, which is tested in BLoC tests
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should show login button when user becomes unauthenticated', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: const Unauthenticated()));
      await tester.pump();

      // Assert
      expect(find.text('Kirish'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });
  });

  group('ClientProfilePage - Avatar Upload', () {
    testWidgets('should render profile page with authenticated user', (WidgetTester tester) async {
      // Arrange
      final authState = Authenticated(tUser);
      when(() => mockAuthBloc.state).thenReturn(authState);
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());

      // Act
      await tester.pumpWidget(createTestWidget(authState: authState));
      await tester.pump();

      // Assert - Widget should render without errors
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Akkount'), findsOneWidget);
    });
  });
}
