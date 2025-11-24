# Build Configuration Guide

This project contains two apps (Client and Merchant) with support for multiple environments (Development, Staging, Production).

## Configuration System

The app uses `AppConfig` to manage environment-specific and app-specific configurations. The configuration is set at runtime based on build arguments.

## Build Flavors

### Android Flavors

The Android build uses product flavors to create different app variants:

- **App Types**: `client`, `merchant`
- **Environments**: `dev`, `staging`, `prod`

Combinations:
- `clientDev` - Client app, Development environment
- `clientStaging` - Client app, Staging environment
- `clientProd` - Client app, Production environment
- `merchantDev` - Merchant app, Development environment
- `merchantStaging` - Merchant app, Staging environment
- `merchantProd` - Merchant app, Production environment

### Package Names

- **Client Dev**: `uz.wedy.app.dev`
- **Client Staging**: `uz.wedy.app.staging`
- **Client Prod**: `uz.wedy.app`
- **Merchant Dev**: `uz.wedy.business.dev`
- **Merchant Staging**: `uz.wedy.business.staging`
- **Merchant Prod**: `uz.wedy.business`

## Building Apps

### Using Build Scripts

We provide convenient shell scripts for building:

#### APK Builds (for direct installation)

```bash
# Client App
./scripts/build_client_dev.sh      # Development
./scripts/build_client_prod.sh     # Production

# Merchant App
./scripts/build_merchant_dev.sh    # Development
./scripts/build_merchant_prod.sh  # Production
```

#### App Bundle Builds (for Google Play Store)

```bash
# Client App
./scripts/build_client_dev_bundle.sh      # Development
./scripts/build_client_staging_bundle.sh  # Staging
./scripts/build_client_prod_bundle.sh    # Production

# Merchant App
./scripts/build_merchant_dev_bundle.sh      # Development
./scripts/build_merchant_staging_bundle.sh  # Staging
./scripts/build_merchant_prod_bundle.sh    # Production
```

### Manual Build Commands

#### Client App

**Development:**
```bash
flutter build apk \
  --target=lib/apps/client/main.dart \
  --flavor=clientDev \
  --dart-define=ENVIRONMENT=development \
  --release
```

**Staging:**
```bash
flutter build apk \
  --target=lib/apps/client/main.dart \
  --flavor=clientStaging \
  --dart-define=ENVIRONMENT=staging \
  --release
```

**Production:**
```bash
flutter build apk \
  --target=lib/apps/client/main.dart \
  --flavor=clientProd \
  --dart-define=ENVIRONMENT=production \
  --release
```

#### Merchant App

**Development:**
```bash
flutter build apk \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantDev \
  --dart-define=ENVIRONMENT=development \
  --release
```

**Staging:**
```bash
flutter build apk \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantStaging \
  --dart-define=ENVIRONMENT=staging \
  --release
```

**Production:**
```bash
flutter build apk \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantProd \
  --dart-define=ENVIRONMENT=production \
  --release
```

### Building App Bundles (AAB)

App bundles are required for Google Play Store uploads. Use `flutter build appbundle` instead of `flutter build apk`:

**Client Production Bundle:**
```bash
flutter build appbundle \
  --target=lib/apps/client/main.dart \
  --flavor=clientProd \
  --dart-define=ENVIRONMENT=production \
  --release
```

**Merchant Production Bundle:**
```bash
flutter build appbundle \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantProd \
  --dart-define=ENVIRONMENT=production \
  --release
```

## Running Apps

### Using Run Scripts

```bash
# Client App
./scripts/run_client_dev.sh [device_id]

# Merchant App
./scripts/run_merchant_dev.sh [device_id]
```

### Manual Run Commands

**Client Development:**
```bash
flutter run \
  --target=lib/apps/client/main.dart \
  --flavor=clientDev \
  --dart-define=ENVIRONMENT=development
```

**Merchant Development:**
```bash
flutter run \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantDev \
  --dart-define=ENVIRONMENT=development
```

## Environment Configuration

The `AppConfig` class automatically sets the following based on environment:

### Development
- Base URL: `http://api.abubyte.uz`
- Logging: Enabled
- Analytics: Disabled

### Staging
- Base URL: `https://staging-api.wedy.uz`
- Logging: Enabled
- Analytics: Enabled

### Production
- Base URL: `https://api.wedy.uz`
- Logging: Disabled
- Analytics: Enabled

## iOS Configuration

For iOS, you'll need to create separate schemes in Xcode for each flavor. The environment is still set via `--dart-define=ENVIRONMENT=...`.

## Customizing Configuration

To add new environment variables or change existing ones, edit:
- `lib/core/config/app_config.dart` - Main configuration class
- `lib/core/constants/api_constants.dart` - API endpoints (uses AppConfig)

## Cleaning Project

To clean all build artifacts and start fresh:

```bash
./scripts/clean.sh
```

This script will:
1. Clean Android Gradle build artifacts (`./gradlew clean`)
2. Clean Flutter build artifacts (`flutter clean`)
3. Fetch Flutter dependencies (`flutter pub get`)
4. Clear the terminal

## Notes

- Make sure to make the build scripts executable: `chmod +x scripts/*.sh`
- For production builds, ensure you have proper signing configurations set up in `android/app/build.gradle.kts`
- The debug banner is automatically hidden in production builds
- Package names are automatically set based on flavor combinations
- **App Bundles (AAB)** are required for Google Play Store uploads
- **APK files** are useful for direct installation, testing, and distribution outside Play Store
- Production app bundles should be properly signed before uploading to Play Store
- Use `./scripts/clean.sh` when experiencing build issues or before major builds

