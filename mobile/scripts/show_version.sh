#!/bin/bash

# Show current app versions
# Usage: ./scripts/show_version.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$MOBILE_DIR"

echo "📱 Wedy App Versions"
echo ""

# Get pubspec.yaml version (for iOS)
if [ -f "pubspec.yaml" ]; then
    PUBSPEC_VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
    PUBSPEC_VERSION_NAME=$(echo $PUBSPEC_VERSION | cut -d'+' -f1)
    PUBSPEC_BUILD=$(echo $PUBSPEC_VERSION | cut -d'+' -f2)
    echo "pubspec.yaml (for iOS/Flutter tooling):"
    echo "  Version: $PUBSPEC_VERSION"
    echo "  Note: Synced with client app version"
    echo ""
fi

# Get versions from version_config.yaml
if [ -f "version_config.yaml" ]; then
    # Extract client version - handle comments by taking first field after colon
    CLIENT_VERSION=$(awk '/^client:/{flag=1; next} flag && /^  version:/{gsub(/"/, "", $2); print $2; exit} flag && /^[^ ]/{flag=0}' version_config.yaml)
    CLIENT_BUILD=$(awk '/^client:/{flag=1; next} flag && /^  build_number:/{print $2; exit} flag && /^[^ ]/{flag=0}' version_config.yaml)
    
    # Extract merchant version
    MERCHANT_VERSION=$(awk '/^merchant:/{flag=1; next} flag && /^  version:/{gsub(/"/, "", $2); print $2; exit} flag && /^[^ ]/{flag=0}' version_config.yaml)
    MERCHANT_BUILD=$(awk '/^merchant:/{flag=1; next} flag && /^  build_number:/{print $2; exit} flag && /^[^ ]/{flag=0}' version_config.yaml)
    
    echo "Client App:"
    echo "  Version Name: $CLIENT_VERSION"
    echo "  Build Number: $CLIENT_BUILD"
    echo "  Full Version: $CLIENT_VERSION+$CLIENT_BUILD"
    echo ""
    
    echo "Merchant App:"
    echo "  Version Name: $MERCHANT_VERSION"
    echo "  Build Number: $MERCHANT_BUILD"
    echo "  Full Version: $MERCHANT_VERSION+$MERCHANT_BUILD"
    echo ""
else
    echo "⚠️  version_config.yaml not found"
    echo ""
fi

# Get Android version info from build.gradle.kts
if [ -f "android/app/build.gradle.kts" ]; then
    echo "Android Configuration (build.gradle.kts):"
    CLIENT_GRADLE_VERSION=$(grep -A 10 'create("client")' android/app/build.gradle.kts | grep 'versionName' | head -1 | awk -F'"' '{print $2}')
    CLIENT_GRADLE_BUILD=$(grep -A 10 'create("client")' android/app/build.gradle.kts | grep 'versionCode' | head -1 | awk '{print $3}')
    
    MERCHANT_GRADLE_VERSION=$(grep -A 10 'create("merchant")' android/app/build.gradle.kts | grep 'versionName' | head -1 | awk -F'"' '{print $2}')
    MERCHANT_GRADLE_BUILD=$(grep -A 10 'create("merchant")' android/app/build.gradle.kts | grep 'versionCode' | head -1 | awk '{print $3}')
    
    echo "  Client:   versionCode = $CLIENT_GRADLE_BUILD, versionName = \"$CLIENT_GRADLE_VERSION\""
    echo "  Merchant: versionCode = $MERCHANT_GRADLE_BUILD, versionName = \"$MERCHANT_GRADLE_VERSION\""
    echo ""
fi

# Show flavor-specific info
echo "Flavor-Specific Versions:"
echo "  Client Dev:      $CLIENT_VERSION+$CLIENT_BUILD (dev)"
echo "  Client Staging:  $CLIENT_VERSION+$CLIENT_BUILD (staging)"
echo "  Client Prod:     $CLIENT_VERSION+$CLIENT_BUILD"
echo "  Merchant Dev:    $MERCHANT_VERSION+$MERCHANT_BUILD (dev)"
echo "  Merchant Staging: $MERCHANT_VERSION+$MERCHANT_BUILD (staging)"
echo "  Merchant Prod:   $MERCHANT_VERSION+$MERCHANT_BUILD"
echo ""

