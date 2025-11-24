#!/bin/bash

# Build script for Merchant App - Production
# Usage: ./scripts/build_merchant_prod.sh

set -e

echo "🚀 Building Wedy Merchant App (Production)..."
echo ""

flutter build apk \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantProd \
  --dart-define=ENVIRONMENT=production \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 APK location: build/app/outputs/flutter-apk/app-merchant-prod-release.apk"

