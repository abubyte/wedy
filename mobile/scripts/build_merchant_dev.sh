#!/bin/bash

# Build script for Merchant App - Development
# Usage: ./scripts/build_merchant_dev.sh

set -e

echo "🚀 Building Wedy Merchant App (Development)..."
echo ""

flutter build apk \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantDev \
  --dart-define=ENVIRONMENT=development \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 APK location: build/app/outputs/flutter-apk/app-merchant-dev-release.apk"

