#!/bin/bash

# Run script for Merchant App - Development
# Usage: ./scripts/run_merchant_dev.sh [device_id]

set -e

DEVICE=${1:-""}

if [ -z "$DEVICE" ]; then
    echo "🚀 Running Wedy Merchant App (Development)..."
    flutter run \
      --target=lib/apps/merchant/main.dart \
      --flavor=merchantDev \
      --dart-define=ENVIRONMENT=development
else
    echo "🚀 Running Wedy Merchant App (Development) on device: $DEVICE..."
    flutter run \
      --target=lib/apps/merchant/main.dart \
      --flavor=merchantDev \
      --dart-define=ENVIRONMENT=development \
      -d "$DEVICE"
fi

