#!/bin/bash

# Build script for Client App Bundle - Staging
# Usage: ./scripts/build_client_staging_bundle.sh

set -e

echo "🚀 Building Wedy Client App Bundle (Staging)..."
echo ""

flutter build appbundle \
  --target=lib/apps/client/main.dart \
  --flavor=clientStaging \
  --dart-define=ENVIRONMENT=staging \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 AAB location: build/app/outputs/bundle/clientStagingRelease/app-client-staging-release.aab"

