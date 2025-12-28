#!/bin/bash

# Script to check keystore SHA1 fingerprint
# Usage: ./scripts/check_keystore_fingerprint.sh [keystore_path] [store_password]

set -e

KEYSTORE_PATH=${1:-"android/app/wedy-release-key.jks"}
STORE_PASSWORD=${2:-""}

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ Keystore not found at: $KEYSTORE_PATH"
    exit 1
fi

if [ -z "$STORE_PASSWORD" ]; then
    # Try to read from key.properties
    if [ -f "android/key.properties" ]; then
        STORE_PASSWORD=$(grep "storePassword=" android/key.properties | cut -d'=' -f2)
    fi
fi

if [ -z "$STORE_PASSWORD" ]; then
    echo "⚠️  Please provide store password:"
    read -sp "Store password: " STORE_PASSWORD
    echo ""
fi

echo "🔍 Checking keystore fingerprint..."
echo "   Keystore: $KEYSTORE_PATH"
echo ""

keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" 2>&1 | grep -A 2 "SHA1:" || {
    echo "❌ Failed to read keystore. Check password and keystore path."
    exit 1
}

echo ""
echo "📋 Expected fingerprint (from Google Play):"
echo "   SHA1: 2D:95:7C:D1:61:AD:F9:42:EC:BD:06:91:CF:FC:A3:7C:26:93:5A:5B"
echo ""
echo "✅ If fingerprints match, you can use this keystore"
echo "❌ If they don't match, you need to use the original keystore file"


