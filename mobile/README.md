# Wedy Mobile App

<div align="center">

**Flutter mobile applications for the Wedy wedding services platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.9+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Running the App](#running-the-app)
- [Building](#building)
- [Testing](#testing)
- [Code Generation](#code-generation)
- [Dependencies](#dependencies)
- [Development Guidelines](#development-guidelines)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The Wedy mobile app is a shared Flutter codebase that powers two separate applications:

1. **Client App** - For engaged couples to discover and book wedding services
2. **Merchant App** - For service providers to manage their business and services

### Key Highlights

- 🏗️ **Clean Architecture** - Separation of concerns with domain, data, and presentation layers
- 🎨 **BLoC Pattern** - Predictable state management with `flutter_bloc`
- 🧭 **GoRouter** - Declarative navigation with deep linking support
- 🔐 **Secure Storage** - JWT tokens and sensitive data stored securely
- 🧪 **Comprehensive Testing** - Unit, widget, and integration tests
- 🎭 **Flavors** - Separate builds for client/merchant and dev/staging/prod
- 📱 **Responsive Design** - Adaptive UI with `flutter_screenutil`

---

## 🏗️ Architecture

The app follows **Clean Architecture** principles with three main layers:

### Domain Layer
- **Entities**: Core business objects (User, Service, etc.)
- **Repositories**: Abstract interfaces defining data contracts
- **Use Cases**: Business logic operations

### Data Layer
- **Data Sources**: Remote (API) and local (storage) data sources
- **Models/DTOs**: Data transfer objects with JSON serialization
- **Repository Implementations**: Concrete implementations of domain repositories

### Presentation Layer
- **BLoC**: State management (Events, States, Bloc)
- **Screens**: UI pages
- **Widgets**: Reusable UI components

### Dependency Flow
```
Presentation → Domain ← Data
```

The presentation layer depends on the domain layer, and the data layer implements domain interfaces. This ensures business logic is independent of external frameworks.

---

## 📁 Project Structure

```
mobile/
├── lib/
│   ├── apps/
│   │   ├── client/          # Client app specific code
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   └── pages/       # Client pages (home, profile, etc.)
│   │   └── merchant/        # Merchant app specific code
│   │       ├── main.dart
│   │       ├── app.dart
│   │       └── pages/       # Merchant pages (dashboard, services, etc.)
│   │
│   ├── core/                # Core functionality
│   │   ├── config/          # App configuration (flavors, environments)
│   │   ├── constants/       # App-wide constants
│   │   ├── di/              # Dependency injection (GetIt)
│   │   ├── errors/           # Error handling (Failures)
│   │   ├── network/         # Network setup (Dio, interceptors)
│   │   ├── theme/           # App theme (colors, text styles)
│   │   └── utils/           # Utility functions
│   │
│   ├── features/            # Feature modules (Clean Architecture)
│   │   ├── auth/            # Authentication feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── profile/         # User profile feature
│   │   ├── service/         # Services feature
│   │   └── reviews/         # Reviews feature
│   │
│   └── shared/              # Shared code
│       ├── navigation/      # Navigation setup (GoRouter)
│       └── widgets/          # Shared widgets
│
├── test/                     # Test files
│   ├── features/            # Feature tests
│   └── helpers/             # Test helpers
│
├── assets/                    # Assets (images, fonts, icons)
├── scripts/                  # Build and utility scripts
└── pubspec.yaml             # Dependencies
```

---

## ✨ Features

### Implemented Features

#### 🔐 Authentication
- Phone number-based OTP authentication
- User registration with profile completion
- JWT token management (access & refresh tokens)
- Automatic token refresh
- Secure local storage

#### 👤 Profile Management
- View user profile
- Update profile information
- Upload and update avatar
- Profile data persistence

#### 🛍️ Services
- Browse services with pagination
- Search and filter services
- View service details
- Service interactions (like, save, share)
- Featured services display

### Planned Features

- Reviews and ratings
- Categories and subcategories
- Favorites management
- Chat/messaging
- Payment integration
- Push notifications
- Location-based services

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.9.0 or higher
- **Dart SDK**: 3.9.0 or higher
- **Android Studio** / **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wedy/mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (for JSON serialization, Retrofit, etc.)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure environment**
   - Update `lib/core/config/app_config.dart` with your API endpoints
   - For development, the default is `http://localhost:8000`

### Configuration

#### App Flavors

The app supports multiple flavors:

- **App Types**: `client` | `merchant`
- **Environments**: `development` | `staging` | `production`

Configuration is managed in `lib/core/config/app_config.dart`:

```dart
AppConfig.initialize(
  appType: AppType.client,      // or AppType.merchant
  environment: Environment.dev,  // or Environment.staging, Environment.prod
);
```

#### API Configuration

Update the base URL in `app_config.dart`:

```dart
static const Map<Environment, String> _baseUrls = {
  Environment.dev: 'http://localhost:8000',  // Change to your dev server
  Environment.staging: 'https://staging-api.wedy.uz',
  Environment.prod: 'https://api.wedy.uz',
};
```

For physical device testing, use your computer's IP address:
```dart
Environment.dev: 'http://192.168.1.100:8000',  // Your local IP
```

---

## 🏃 Running the App

### Development Mode

#### Client App (Development)
```bash
# Using Flutter CLI
flutter run --flavor clientDev -t lib/apps/client/main.dart

# Or use the provided script
./scripts/run_client_dev.sh
```

#### Merchant App (Development)
```bash
# Using Flutter CLI
flutter run --flavor merchantDev -t lib/apps/merchant/main.dart

# Or use the provided script
./scripts/run_merchant_dev.sh
```

### Debugging in VS Code

1. Open the project in VS Code
2. Go to Run and Debug (F5)
3. Select the configuration:
   - `Client Dev` - Run client app in development
   - `Merchant Dev` - Run merchant app in development
   - `Client Staging` - Run client app in staging
   - `Merchant Staging` - Run merchant app in staging

The launch configurations are in `.vscode/launch.json`.

### Running on Specific Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id> --flavor clientDev -t lib/apps/client/main.dart
```

---

## 📦 Building

### Android

#### Development Build
```bash
# APK
./scripts/build_client_dev.sh

# App Bundle
./scripts/build_client_dev_bundle.sh
```

#### Production Build
```bash
# APK
./scripts/build_client_prod.sh

# App Bundle (for Play Store)
./scripts/build_client_prod_bundle.sh
```

### iOS

```bash
# Build for iOS (requires macOS and Xcode)
flutter build ios --flavor clientProd -t lib/apps/client/main.dart --release
```

### Build Scripts

All build scripts are in the `scripts/` directory:

- `build_client_dev.sh` - Client dev APK
- `build_client_prod.sh` - Client production APK
- `build_merchant_dev.sh` - Merchant dev APK
- `build_merchant_prod.sh` - Merchant production APK
- `build_*_bundle.sh` - App bundle versions (for Play Store)

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/domain/usecases/send_otp_test.dart

# Run tests with coverage
flutter test --coverage
```

### Test Structure

Tests follow the same structure as the source code:

```
test/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── profile/
│   └── service/
└── helpers/
```

### Test Types

1. **Unit Tests** - Test use cases, repositories, and business logic
2. **Widget Tests** - Test UI components and user interactions
3. **BLoC Tests** - Test state management using `bloc_test`

### Example Test

```dart
// test/features/auth/domain/usecases/send_otp_test.dart
test('should send OTP successfully', () async {
  // Arrange
  when(() => mockRepository.sendOtp(any()))
      .thenAnswer((_) async => const Right(unit));

  // Act
  final result = await useCase('901234567');

  // Assert
  expect(result, const Right(unit));
  verify(() => mockRepository.sendOtp('901234567')).called(1);
});
```

---

## 🔧 Code Generation

The project uses code generation for:

- **JSON Serialization** (`json_serializable`)
- **Retrofit API Clients** (`retrofit_generator`)
- **Hive Adapters** (`hive_generator`)

### Generate Code

```bash
# Generate all code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Generated Files

Generated files are marked with `.g.dart` extension:
- `user_model.g.dart`
- `auth_remote_datasource.g.dart`
- `service_dto.g.dart`

**Note**: Never edit generated files directly. Modify the source files and regenerate.

---

## 📚 Dependencies

### Core Dependencies

| Package | Purpose | Version |
|---------|---------|---------|
| `flutter_bloc` | State management | ^9.1.1 |
| `go_router` | Navigation | ^16.2.0 |
| `dio` | HTTP client | ^5.3.2 |
| `retrofit` | REST API client | ^4.0.3 |
| `get_it` | Dependency injection | ^7.6.4 |
| `flutter_secure_storage` | Secure storage | ^9.0.0 |
| `dartz` | Functional programming | ^0.10.1 |

### UI Dependencies

| Package | Purpose |
|---------|---------|
| `iconsax_plus` | Icon library |
| `cached_network_image` | Image caching |
| `flutter_screenutil` | Responsive design |
| `shimmer` | Loading placeholders |
| `lottie` | Animations |

### Development Dependencies

| Package | Purpose |
|---------|---------|
| `build_runner` | Code generation |
| `json_serializable` | JSON serialization |
| `retrofit_generator` | Retrofit code generation |
| `bloc_test` | BLoC testing |
| `mocktail` | Mocking for tests |
| `flutter_lints` | Linting rules |

See `pubspec.yaml` for the complete list.

---

## 📖 Development Guidelines

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Follow the existing code structure and naming conventions

### Adding a New Feature

1. **Create feature structure**:
   ```
   lib/features/new_feature/
   ├── data/
   │   ├── datasources/
   │   ├── models/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── presentation/
       ├── bloc/
       ├── screens/
       └── widgets/
   ```

2. **Implement layers** (in order):
   - Domain (entities, repository interface, use cases)
   - Data (models, data sources, repository implementation)
   - Presentation (BLoC, screens, widgets)

3. **Register dependencies** in `lib/core/di/injection_container.dart`

4. **Write tests** for each layer

5. **Add routes** in `lib/shared/navigation/app_router.dart`

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `lowerCamelCase` or `UPPER_SNAKE_CASE`
- **Private members**: `_leadingUnderscore`

### BLoC Pattern

```dart
// Event
class LoadUserEvent extends UserEvent {
  final String userId;
  const LoadUserEvent(this.userId);
}

// State
class UserLoaded extends UserState {
  final User user;
  const UserLoaded(this.user);
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUserUseCase;
  
  UserBloc({required this.getUserUseCase}) : super(UserInitial()) {
    on<LoadUserEvent>(_onLoadUser);
  }
  
  Future<void> _onLoadUser(LoadUserEvent event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await getUserUseCase(event.userId);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }
}
```

### Error Handling

Use `Either<Failure, T>` from `dartz` for error handling:

```dart
Future<Either<Failure, User>> getUser(String id) async {
  try {
    final user = await remoteDataSource.getUser(id);
    return Right(user);
  } on DioException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### API Integration

1. **Define DTO** in `data/models/`:
   ```dart
   @JsonSerializable()
   class UserDto {
     final String id;
     final String name;
     
     factory UserDto.fromJson(Map<String, dynamic> json) =>
         _$UserDtoFromJson(json);
     Map<String, dynamic> toJson() => _$UserDtoToJson(this);
   }
   ```

2. **Create Remote Data Source**:
   ```dart
   @RestApi()
   abstract class UserRemoteDataSource {
     @GET('/api/v1/users/{id}')
     Future<UserDto> getUser(@Path('id') String id);
   }
   ```

3. **Implement Repository**:
   ```dart
   class UserRepositoryImpl implements UserRepository {
     final UserRemoteDataSource remoteDataSource;
     
     @override
     Future<Either<Failure, User>> getUser(String id) async {
       try {
         final dto = await remoteDataSource.getUser(id);
         return Right(dto.toEntity());
       } on DioException catch (e) {
         return Left(ErrorInterceptor.handleDioError(e));
       }
     }
   }
   ```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Code Generation Errors

**Problem**: `*.g.dart` files are missing or outdated.

**Solution**:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. Dependency Injection Errors

**Problem**: `GetIt` not finding registered dependencies.

**Solution**: Ensure `di.init()` is called in `main.dart` before using the app:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();  // Must be called first
  runApp(MyApp());
}
```

#### 3. Network Errors

**Problem**: Cannot connect to API.

**Solution**:
- Check API base URL in `app_config.dart`
- For physical device, use your computer's IP address instead of `localhost`
- Ensure backend server is running
- Check network permissions in `AndroidManifest.xml` / `Info.plist`

#### 4. Build Errors

**Problem**: Build fails with flavor errors.

**Solution**: Ensure flavors are configured in:
- `android/app/build.gradle.kts` (Android)
- `ios/Runner.xcodeproj` (iOS)

#### 5. Test Failures

**Problem**: Tests fail with mock errors.

**Solution**: Register fallback values in `setUpAll`:
```dart
setUpAll(() {
  registerFallbackValue(FakeUserEvent());
  registerFallbackValue(User(id: '', name: '', ...));
});
```

### Getting Help

- Check existing issues in the repository
- Review Flutter documentation: https://flutter.dev/docs
- Ask questions in team chat or create an issue

---

## 📝 License

This project is part of the Wedy platform. See the main repository for license information.

---

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes following the development guidelines
3. Write tests for new features
4. Ensure all tests pass: `flutter test`
5. Run code analysis: `flutter analyze`
6. Submit a pull request

---

## 📞 Support

For questions or issues:
- Create an issue in the repository
- Contact the development team
- Check the main project README for more information

---

**Happy Coding! 🚀**
