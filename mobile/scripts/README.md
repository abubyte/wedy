# Build Scripts

This directory contains build and run scripts for the Wedy mobile apps.

## Quick Start

### Building APK for Production

```bash
# Client App - Production
./scripts/build_client_prod.sh

# Merchant App - Production
./scripts/build_merchant_prod.sh
```

### Building App Bundle for Production (Google Play Store)

```bash
# Client App - Production Bundle
./scripts/build_client_prod_bundle.sh

# Merchant App - Production Bundle
./scripts/build_merchant_prod_bundle.sh
```

### Building for Development

```bash
# Client App - Development
./scripts/build_client_dev.sh

# Merchant App - Development
./scripts/build_merchant_dev.sh
```

### Running in Development

```bash
# Client App
./scripts/run_client_dev.sh

# Merchant App
./scripts/run_merchant_dev.sh

# Run on specific device
./scripts/run_client_dev.sh <device_id>
```

### Cleaning Project

```bash
# Clean all build artifacts and fetch dependencies
./scripts/clean.sh
```

This will:
- Clean Android Gradle build artifacts (`./gradlew clean`)
- Clean Flutter build artifacts (`flutter clean`)
- Fetch Flutter dependencies (`flutter pub get`)
- Clear the terminal

### Generating App Icons

```bash
# Generate icons for both apps
./scripts/generate_icons.sh

# Generate only client app icons
./scripts/generate_icons.sh client

# Generate only merchant app icons
./scripts/generate_icons.sh merchant
```

**Note:** You need to create icon images first:
- `assets/icons/client_icon.png` (1024x1024px)
- `assets/icons/merchant_icon.png` (1024x1024px)

See `docs/APP_ICONS_GUIDE.md` for detailed instructions.

### Version Management

**Each app (Client and Merchant) has independent versions!**

```bash
# Show current versions for both apps
./scripts/show_version.sh

# Bump client app build number (most common)
./scripts/bump_version.sh build client

# Bump merchant app build number
./scripts/bump_version.sh build merchant

# Bump patch version (1.0.0 → 1.0.1)
./scripts/bump_version.sh patch client
./scripts/bump_version.sh patch merchant

# Bump minor version (1.0.0 → 1.1.0)
./scripts/bump_version.sh minor client

# Bump major version (1.0.0 → 2.0.0)
./scripts/bump_version.sh major merchant

# Sync versions from version_config.yaml to build.gradle.kts
./scripts/sync_versions.sh
```

See `docs/VERSION_MANAGEMENT.md` for detailed version management guide.

## Available Scripts

### APK Build Scripts

- `build_client_dev.sh` - Build Client app APK for Development
- `build_client_prod.sh` - Build Client app APK for Production
- `build_merchant_dev.sh` - Build Merchant app APK for Development
- `build_merchant_prod.sh` - Build Merchant app APK for Production

### App Bundle Build Scripts (for Google Play Store)

- `build_client_dev_bundle.sh` - Build Client app bundle for Development
- `build_client_staging_bundle.sh` - Build Client app bundle for Staging
- `build_client_prod_bundle.sh` - Build Client app bundle for Production
- `build_merchant_dev_bundle.sh` - Build Merchant app bundle for Development
- `build_merchant_staging_bundle.sh` - Build Merchant app bundle for Staging
- `build_merchant_prod_bundle.sh` - Build Merchant app bundle for Production

### Run Scripts

- `run_client_dev.sh` - Run Client app in Development mode
- `run_merchant_dev.sh` - Run Merchant app in Development mode

### Utility Scripts

- `clean.sh` - Clean all build artifacts (Gradle, Flutter, and fetch dependencies)
- `generate_icons.sh` - Generate app icons for Client and/or Merchant apps
- `bump_version.sh` - Bump app version (major, minor, patch, or build)
- `show_version.sh` - Display current app version information
- `sync_version.sh` - Syncronize version configuration

## Environment Variables

The scripts automatically set the `ENVIRONMENT` variable via `--dart-define`:
- `development` - Development environment
- `staging` - Staging environment (manual build required)
- `production` - Production environment

## Notes

- All scripts are executable and can be run directly
- Make sure Flutter is in your PATH
- For iOS builds, you'll need to configure Xcode schemes separately
- Production builds require proper signing configuration
- **App Bundles (AAB)** are required for Google Play Store uploads
- **APK files** are useful for direct installation and testing
- Production app bundles should be signed before uploading to Play Store

