#!/bin/bash

# Build script for Client App - Production
# Usage: ./scripts/build_client_prod.sh

set -e

echo "🚀 Building Wedy Client App (Production)..."
echo ""

flutter build apk \
  --target=lib/apps/client/main.dart \
  --flavor=clientProd \
  --dart-define=ENVIRONMENT=production \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 APK location: build/app/outputs/flutter-apk/app-client-prod-release.apk"

