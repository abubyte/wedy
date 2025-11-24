#!/bin/bash

# Build script for Client App Bundle - Production
# Usage: ./scripts/build_client_prod_bundle.sh

set -e

echo "🚀 Building Wedy Client App Bundle (Production)..."
echo ""

flutter build appbundle \
  --target=lib/apps/client/main.dart \
  --flavor=clientProd \
  --dart-define=ENVIRONMENT=production \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 AAB location: build/app/outputs/bundle/clientProdRelease/app-client-prod-release.aab"
echo ""
echo "⚠️  Remember to sign the bundle before uploading to Google Play Store!"

