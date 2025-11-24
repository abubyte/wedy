#!/bin/bash

# Build script for Merchant App Bundle - Development
# Usage: ./scripts/build_merchant_dev_bundle.sh

set -e

echo "🚀 Building Wedy Merchant App Bundle (Development)..."
echo ""

flutter build appbundle \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantDev \
  --dart-define=ENVIRONMENT=development \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 AAB location: build/app/outputs/bundle/merchantDevRelease/app-merchant-dev-release.aab"

