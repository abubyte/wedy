#!/bin/bash

# Build script for Client App - Development
# Usage: ./scripts/build_client_dev.sh

set -e

echo "🚀 Building Wedy Client App (Development)..."
echo ""

flutter build apk \
  --target=lib/apps/client/main.dart \
  --flavor=clientDev \
  --dart-define=ENVIRONMENT=development \
  --release

echo ""
echo "✅ Build completed successfully!"
echo "📦 APK location: build/app/outputs/flutter-apk/app-client-dev-release.apk"

