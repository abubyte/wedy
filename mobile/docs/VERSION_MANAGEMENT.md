# Version Management Guide

This guide explains how to manage app versions for the Wedy Client and Merchant apps.

## Version Format

Versions follow the format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

- **MAJOR**: Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR**: New features, backward compatible (e.g., 1.0.0 → 1.1.0)
- **PATCH**: Bug fixes (e.g., 1.0.0 → 1.0.1)
- **BUILD_NUMBER**: Increments with each build (required by app stores)

Example: `1.2.3+45` means version 1.2.3, build 45

## Version Management

**Each app (Client and Merchant) has its own independent version!**

Versions are managed in **`version_config.yaml`**:
```yaml
client:
  version: "1.0.0"
  build_number: 1

merchant:
  version: "1.0.0"
  build_number: 1
```

These versions are synced to:
- **Android**: `build.gradle.kts` (per flavor: client/merchant) - uses flavor-specific versions
- **iOS**: `pubspec.yaml` - synced with client app version (iOS uses `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER`)

### About pubspec.yaml Version

The `version` field in `pubspec.yaml` is:
- **Synced with Client app version** (automatically via `sync_versions.sh`)
- **Used by iOS** for `CFBundleShortVersionString` and `CFBundleVersion`
- **Required by Flutter tooling** (cannot be removed)

**Important:** 
- When you bump the client app version, `pubspec.yaml` is automatically updated
- When you bump the merchant app version, `pubspec.yaml` stays with client version
- For iOS builds, the version comes from `pubspec.yaml` (which matches client app)
- For Android builds, each flavor uses its own version from `build.gradle.kts`

## Version Management

### Show Current Version

```bash
./scripts/show_version.sh
```

### Bump Version

**You must specify which app to bump:**

```bash
# Bump client app build number (most common)
./scripts/bump_version.sh build client

# Bump merchant app build number
./scripts/bump_version.sh build merchant

# Bump client app patch version (1.0.0 → 1.0.1)
./scripts/bump_version.sh patch client

# Bump merchant app minor version (1.0.0 → 1.1.0)
./scripts/bump_version.sh minor merchant

# Bump client app major version (1.0.0 → 2.0.0)
./scripts/bump_version.sh major client
```

### Manual Version Update

Edit `version_config.yaml`:
```yaml
client:
  version: "1.2.3"
  build_number: 45

merchant:
  version: "2.0.0"
  build_number: 10
```

Then sync to build files (this also updates pubspec.yaml):
```bash
./scripts/sync_versions.sh
```

**Note:** `pubspec.yaml` version will be automatically synced to match the client app version (for iOS compatibility).

## Environment-Specific Versions

Currently, all flavors (dev/staging/prod) share the same base version from `pubspec.yaml`, but:

- **Dev builds** get suffix: `-dev` (e.g., "1.0.0-dev")
- **Staging builds** get suffix: `-staging` (e.g., "1.0.0-staging")
- **Prod builds** have no suffix (e.g., "1.0.0")

This is configured in `android/app/build.gradle.kts`:
```kotlin
create("dev") {
    versionNameSuffix = "-dev"
}
```

## Version Strategy

### For Development
- Use `build` bump for each test build
- Build number increments automatically

### For Staging
- Use `patch` or `minor` bump before staging release
- Reset build number if needed

### For Production
- Use `major`, `minor`, or `patch` based on changes
- Build number must be higher than previous production release
- Follow semantic versioning principles

## App Store Requirements

### Google Play Store
- `versionCode` (build number) must always increase
- `versionName` (version string) is for display only
- Each upload must have a higher `versionCode`

### Apple App Store
- `CFBundleVersion` (build number) must be unique and increasing
- `CFBundleShortVersionString` (version string) is for display
- Build numbers must be unique across all versions

## Best Practices

1. **Always increment build number** for each release
2. **Use semantic versioning** for version strings
3. **Keep versions in sync** between client and merchant apps (or use separate versioning)
4. **Document version changes** in release notes
5. **Tag releases** in git with version numbers

## Example Workflow

```bash
# 1. Check current versions
./scripts/show_version.sh

# 2. Bump client app version for new release
./scripts/bump_version.sh patch client  # 1.0.0+1 → 1.0.1+1

# 3. Build and test client app
./scripts/build_client_prod_bundle.sh

# 4. If tests pass, bump build number
./scripts/bump_version.sh build client  # 1.0.1+1 → 1.0.1+2

# 5. Build final release
./scripts/build_client_prod_bundle.sh

# 6. Commit version change
git add version_config.yaml android/app/build.gradle.kts
git commit -m "Bump client app version to 1.0.1+2"
git tag client-v1.0.1+2

# 7. For merchant app (independent versioning)
./scripts/bump_version.sh build merchant  # Merchant: 1.0.0+1 → 1.0.0+2
```

## Separate Versioning for Client/Merchant

✅ **Already implemented!** Each app has independent versioning:

- **Client App**: Managed separately in `version_config.yaml` → `build.gradle.kts` (client flavor)
- **Merchant App**: Managed separately in `version_config.yaml` → `build.gradle.kts` (merchant flavor)

You can bump versions independently:
- Client can be at `2.0.0+10` while Merchant is at `1.5.3+25`
- Each app's version history is completely independent

## Understanding pubspec.yaml Version

The `version` field in `pubspec.yaml` serves a special purpose:

1. **Required by Flutter**: Flutter tooling requires this field
2. **Used by iOS**: iOS builds use `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` from `pubspec.yaml`
3. **Synced with Client App**: Automatically kept in sync with client app version via `sync_versions.sh`

**Why sync with client app?**
- iOS doesn't support flavors the same way Android does
- Simpler to manage: one version for iOS (client app version)
- If you need different iOS versions, you'd need separate Xcode schemes (more complex)

**What this means:**
- ✅ Android: Each app (client/merchant) has independent versions
- ✅ iOS: Uses client app version (from `pubspec.yaml`)
- ✅ When you bump client version → `pubspec.yaml` auto-updates
- ✅ When you bump merchant version → `pubspec.yaml` stays with client version

## Troubleshooting

### Version conflicts in app stores
- Ensure build numbers always increase
- Check previous uploads in Play Console/App Store Connect

### Version not updating
- Clean build: `./scripts/clean.sh`
- Rebuild the app
- Run `./scripts/sync_versions.sh` to sync all versions
- Check `version_config.yaml` is correct

### Version format errors
- Ensure format: `MAJOR.MINOR.PATCH+BUILD`
- No spaces in version string
- Build number must be integer

### pubspec.yaml out of sync
- Run `./scripts/sync_versions.sh` to sync with client app version
- This happens automatically when using `bump_version.sh client`

