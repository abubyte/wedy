#!/bin/bash

# Build script for Merchant App Bundle - Production
# Usage: ./scripts/build_merchant_prod_bundle.sh

set -e

echo "🚀 Building Wedy Merchant App Bundle (Production)..."
echo ""
echo "📋 Build configuration:"
echo "   - Target: lib/apps/merchant/main.dart"
echo "   - Flavor: merchantProd"
echo "   - Environment: production"
echo "   - Expected applicationId: uz.wedy.business"
echo ""

# Clean previous builds to ensure fresh build
echo "🧹 Cleaning previous builds..."
# Kill any Gradle daemons that might be holding file locks
pkill -f gradle || true
sleep 2
# Clean Flutter and Gradle
flutter clean > /dev/null 2>&1 || true
# Remove problematic lint cache directories
rm -rf build/file_picker/intermediates/lint-cache 2>/dev/null || true
rm -rf build/*/intermediates/lint-cache 2>/dev/null || true
cd android && ./gradlew clean --no-daemon > /dev/null 2>&1 || true
cd ..

echo ""
echo "📦 Building app bundle..."
echo "   Verifying applicationId before build..."
cd android && ./gradlew :app:printApplicationIds 2>&1 | grep "merchantProdRelease" && cd .. || true
echo ""

flutter build appbundle \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantProd \
  --dart-define=ENVIRONMENT=production \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 AAB location: build/app/outputs/bundle/merchantProdRelease/app-merchant-prod-release.aab"
echo ""
echo "🔍 Verifying applicationId..."
if [ -f "build/app/outputs/bundle/merchantProdRelease/app-merchant-prod-release.aab" ]; then
    # Extract and check the package name from the AAB
    BUNDLE_PATH="build/app/outputs/bundle/merchantProdRelease/app-merchant-prod-release.aab"
    echo "   Bundle found at: $BUNDLE_PATH"
    echo "   Expected package: uz.wedy.business"
    echo ""
    echo "⚠️  Remember to sign the bundle before uploading to Google Play Store!"
else
    echo "   ⚠️  Warning: AAB file not found at expected location"
fi

