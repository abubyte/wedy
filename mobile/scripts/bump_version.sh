#!/bin/bash

# Version bump script for Wedy apps
# Usage: ./scripts/bump_version.sh [major|minor|patch|build] [client|merchant]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$MOBILE_DIR"

BUMP_TYPE=${1:-"build"}
APP_TYPE=${2:-"client"}

if [ ! -f "version_config.yaml" ]; then
    echo "❌ version_config.yaml not found"
    exit 1
fi

if [ "$APP_TYPE" != "client" ] && [ "$APP_TYPE" != "merchant" ]; then
    echo "❌ Invalid app type. Use: client or merchant"
    exit 1
fi

echo "📦 Bumping $APP_TYPE app version..."
echo ""

# Extract current version from version_config.yaml
if [ "$APP_TYPE" = "client" ]; then
    CURRENT_VERSION=$(grep -A 10 "^client:" version_config.yaml | grep "^  version:" | head -1 | awk '{print $2}' | tr -d '"')
    CURRENT_BUILD=$(grep -A 10 "^client:" version_config.yaml | grep "^  build_number:" | head -1 | awk '{print $2}')
else
    CURRENT_VERSION=$(grep -A 10 "^merchant:" version_config.yaml | grep "^  version:" | head -1 | awk '{print $2}' | tr -d '"')
    CURRENT_BUILD=$(grep -A 10 "^merchant:" version_config.yaml | grep "^  build_number:" | head -1 | awk '{print $2}')
fi

if [ -z "$CURRENT_VERSION" ] || [ -z "$CURRENT_BUILD" ]; then
    echo "❌ Failed to parse current version from version_config.yaml"
    exit 1
fi

echo "Current $APP_TYPE version: $CURRENT_VERSION+$CURRENT_BUILD"
echo "Bump type: $BUMP_TYPE"
echo ""

# Bump version based on type
case $BUMP_TYPE in
    major)
        NEW_VERSION_NAME=$(echo $CURRENT_VERSION | awk -F. '{print $1+1".0.0"}')
        NEW_BUILD=$CURRENT_BUILD
        ;;
    minor)
        NEW_VERSION_NAME=$(echo $CURRENT_VERSION | awk -F. '{print $1"."$2+1".0"}')
        NEW_BUILD=$CURRENT_BUILD
        ;;
    patch)
        NEW_VERSION_NAME=$(echo $CURRENT_VERSION | awk -F. '{print $1"."$2"."$3+1}')
        NEW_BUILD=$CURRENT_BUILD
        ;;
    build)
        NEW_VERSION_NAME=$CURRENT_VERSION
        NEW_BUILD=$((CURRENT_BUILD + 1))
        ;;
    *)
        echo "❌ Invalid bump type. Use: major, minor, patch, or build"
        exit 1
        ;;
esac

NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD"
echo "New $APP_TYPE version: $NEW_VERSION"
echo ""

# Update version_config.yaml
if [ "$APP_TYPE" = "client" ]; then
    sed -i "/^client:/,/^merchant:/ {
        s/^  version:.*/  version: \"$NEW_VERSION_NAME\"/
        s/^  build_number:.*/  build_number: $NEW_BUILD/
    }" version_config.yaml
else
    sed -i "/^merchant:/,/^auto_increment:/ {
        s/^  version:.*/  version: \"$NEW_VERSION_NAME\"/
        s/^  build_number:.*/  build_number: $NEW_BUILD/
    }" version_config.yaml
fi

echo "✅ Updated version_config.yaml: $NEW_VERSION"

# Sync to build.gradle.kts
echo ""
echo "🔄 Syncing to build.gradle.kts..."
"$SCRIPT_DIR/sync_versions.sh"

echo ""
echo "✅ Version bumped and synced successfully!"
echo "   $APP_TYPE app: $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Review the changes in version_config.yaml and build.gradle.kts"
echo "2. Commit the version change"
echo "3. Build and test the app"

