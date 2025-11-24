#!/bin/bash

# Build script for Merchant App Bundle - Staging
# Usage: ./scripts/build_merchant_staging_bundle.sh

set -e

echo "🚀 Building Wedy Merchant App Bundle (Staging)..."
echo ""

flutter build appbundle \
  --target=lib/apps/merchant/main.dart \
  --flavor=merchantStaging \
  --dart-define=ENVIRONMENT=staging \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 AAB location: build/app/outputs/bundle/merchantStagingRelease/app-merchant-staging-release.aab"

