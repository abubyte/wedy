#!/bin/bash

# Build script for Merchant App Bundle - Production
# Usage: ./scripts/build_merchant_prod_bundle.sh

set -e

echo "🚀 Building Wedy Merchant App Bundle (Production)..."
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
echo "⚠️  Remember to sign the bundle before uploading to Google Play Store!"

