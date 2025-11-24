#!/bin/bash

# Sync versions from version_config.yaml to build.gradle.kts
# This script reads version_config.yaml and updates Android build.gradle.kts
# Usage: ./scripts/sync_versions.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$MOBILE_DIR"

if [ ! -f "version_config.yaml" ]; then
    echo "❌ version_config.yaml not found"
    exit 1
fi

BUILD_GRADLE="android/app/build.gradle.kts"

if [ ! -f "$BUILD_GRADLE" ]; then
    echo "❌ $BUILD_GRADLE not found"
    exit 1
fi

echo "🔄 Syncing versions from version_config.yaml to build.gradle.kts..."
echo ""

# Extract client version (simple parsing - assumes YAML format)
CLIENT_VERSION=$(grep -A 10 "^client:" version_config.yaml | grep "^  version:" | head -1 | awk '{print $2}' | tr -d '"')
CLIENT_BUILD=$(grep -A 10 "^client:" version_config.yaml | grep "^  build_number:" | head -1 | awk '{print $2}')

# Extract merchant version
MERCHANT_VERSION=$(grep -A 10 "^merchant:" version_config.yaml | grep "^  version:" | head -1 | awk '{print $2}' | tr -d '"')
MERCHANT_BUILD=$(grep -A 10 "^merchant:" version_config.yaml | grep "^  build_number:" | head -1 | awk '{print $2}')

if [ -z "$CLIENT_VERSION" ] || [ -z "$CLIENT_BUILD" ] || [ -z "$MERCHANT_VERSION" ] || [ -z "$MERCHANT_BUILD" ]; then
    echo "❌ Failed to parse version_config.yaml"
    exit 1
fi

echo "Client App:   $CLIENT_VERSION+$CLIENT_BUILD"
echo "Merchant App: $MERCHANT_VERSION+$MERCHANT_BUILD"
echo ""

# Update build.gradle.kts - Client flavor
sed -i "/create(\"client\") {/,/}/ {
    s/versionCode = [0-9]*/versionCode = $CLIENT_BUILD/
    s/versionName = \"[^\"]*\"/versionName = \"$CLIENT_VERSION\"/
}" "$BUILD_GRADLE"

# Update build.gradle.kts - Merchant flavor
sed -i "/create(\"merchant\") {/,/}/ {
    s/versionCode = [0-9]*/versionCode = $MERCHANT_BUILD/
    s/versionName = \"[^\"]*\"/versionName = \"$MERCHANT_VERSION\"/
}" "$BUILD_GRADLE"

# Update pubspec.yaml to match client app version (for iOS and Flutter tooling)
# iOS uses FLUTTER_BUILD_NAME and FLUTTER_BUILD_NUMBER from pubspec.yaml
PUBSPEC_VERSION="$CLIENT_VERSION+$CLIENT_BUILD"
sed -i "s/^version:.*/version: $PUBSPEC_VERSION/" pubspec.yaml
echo "✅ Updated pubspec.yaml: $PUBSPEC_VERSION (synced with client app for iOS)"

echo ""
echo "✅ Versions synced successfully!"
echo ""
echo "Updated files:"
echo "  $BUILD_GRADLE:"
echo "    Client:   versionCode = $CLIENT_BUILD, versionName = \"$CLIENT_VERSION\""
echo "    Merchant: versionCode = $MERCHANT_BUILD, versionName = \"$MERCHANT_VERSION\""
echo "  pubspec.yaml:"
echo "    version: $PUBSPEC_VERSION (synced with client app - used by iOS)"

