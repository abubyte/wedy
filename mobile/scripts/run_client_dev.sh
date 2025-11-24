#!/bin/bash

# Run script for Client App - Development
# Usage: ./scripts/run_client_dev.sh [device_id]

set -e

DEVICE=${1:-""}

if [ -z "$DEVICE" ]; then
    echo "🚀 Running Wedy Client App (Development)..."
    flutter run \
      --target=lib/apps/client/main.dart \
      --flavor=clientDev \
      --dart-define=ENVIRONMENT=development
else
    echo "🚀 Running Wedy Client App (Development) on device: $DEVICE..."
    flutter run \
      --target=lib/apps/client/main.dart \
      --flavor=clientDev \
      --dart-define=ENVIRONMENT=development \
      -d "$DEVICE"
fi

