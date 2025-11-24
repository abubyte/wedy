#!/bin/bash

# Build script for Client App Bundle - Development
# Usage: ./scripts/build_client_dev_bundle.sh

set -e

echo "🚀 Building Wedy Client App Bundle (Development)..."
echo ""

flutter build appbundle \
  --target=lib/apps/client/main.dart \
  --flavor=clientDev \
  --dart-define=ENVIRONMENT=development \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 AAB location: build/app/outputs/bundle/clientDevRelease/app-client-dev-release.aab"

