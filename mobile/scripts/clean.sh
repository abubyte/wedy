#!/bin/bash

# Clean script - Cleans Flutter and Android build artifacts
# Usage: ./scripts/clean.sh

set +e  # Don't exit on errors - we'll handle them manually

echo "🧹 Cleaning project..."
echo ""

# Get the script directory and navigate to mobile root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$MOBILE_DIR" || exit 1

# Clean Android Gradle (non-blocking - continue even if it fails)
echo "📦 Cleaning Android Gradle..."
if [ -d "android" ]; then
    cd android || exit 1
    if [ -f "./gradlew" ]; then
        # Try to clean, but don't fail if it errors (common with Java toolchain issues)
        # Suppress all output to avoid confusing error messages
        if ./gradlew clean --no-daemon --quiet 2>/dev/null; then
            echo "✅ Android Gradle cleaned successfully"
        else
            # Gradle clean failed - manually clean build directories as fallback
            echo "⚠️  Gradle clean failed, manually cleaning build directories..."
            rm -rf build app/build .gradle 2>/dev/null
            if [ -d "build" ] || [ -d "app/build" ] || [ -d ".gradle" ]; then
                echo "   ⚠️  Some directories could not be removed (may be in use)"
            else
                echo "   ✅ Manually cleaned Android build artifacts"
            fi
        fi
    else
        echo "⚠️  gradlew not found, skipping Android clean"
    fi
    cd .. || exit 1
else
    echo "⚠️  android directory not found, skipping Android clean"
fi

# Clean Flutter (this is critical - must succeed)
echo ""
echo "📦 Cleaning Flutter build artifacts..."
if ! flutter clean; then
    echo "❌ Flutter clean failed"
    exit 1
fi
echo "✅ Flutter cleaned successfully"

# Get dependencies (this is critical - must succeed)
echo ""
echo "📦 Fetching Flutter dependencies..."
if ! flutter pub get; then
    echo "❌ Failed to fetch dependencies"
    exit 1
fi
echo "✅ Dependencies fetched successfully"

# Clear terminal
clear

echo "✅ Clean completed successfully!"
echo ""
echo "Project is now clean and ready for a fresh build."

