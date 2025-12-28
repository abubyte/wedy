#!/bin/bash

# Script to configure an existing keystore for production builds
# Usage: ./scripts/setup_existing_keystore.sh [keystore_path] [key_alias]

set -e

echo "🔐 Setting up existing keystore for production builds..."
echo ""

KEYSTORE_PATH=${1}
KEY_ALIAS=${2}

if [ -z "$KEYSTORE_PATH" ]; then
    read -p "Enter path to your existing keystore file: " KEYSTORE_PATH
fi

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ Keystore file not found at: $KEYSTORE_PATH"
    exit 1
fi

# Get absolute path
KEYSTORE_PATH=$(realpath "$KEYSTORE_PATH")
KEYSTORE_NAME=$(basename "$KEYSTORE_PATH")

echo "📋 Keystore information:"
echo "   Path: $KEYSTORE_PATH"
echo "   Name: $KEYSTORE_NAME"
echo ""

# Copy keystore to android/app if it's not already there
if [ "$(dirname "$KEYSTORE_PATH")" != "$(pwd)/android/app" ]; then
    echo "📦 Copying keystore to android/app/..."
    cp "$KEYSTORE_PATH" "android/app/$KEYSTORE_NAME"
    KEYSTORE_PATH="android/app/$KEYSTORE_NAME"
fi

# Get key alias
if [ -z "$KEY_ALIAS" ]; then
    read -p "Enter key alias (default: check existing key.properties): " KEY_ALIAS
    if [ -z "$KEY_ALIAS" ] && [ -f "android/key.properties" ]; then
        KEY_ALIAS=$(grep "keyAlias=" android/key.properties | cut -d'=' -f2)
        echo "   Using key alias from key.properties: $KEY_ALIAS"
    fi
fi

if [ -z "$KEY_ALIAS" ]; then
    read -p "Enter key alias: " KEY_ALIAS
fi

# Get passwords
read -sp "Enter keystore password: " KEYSTORE_PASSWORD
echo ""
read -sp "Enter key password (press Enter to use same as keystore): " KEY_PASSWORD
echo ""
KEY_PASSWORD=${KEY_PASSWORD:-$KEYSTORE_PASSWORD}

# Verify keystore
echo ""
echo "🔍 Verifying keystore..."
if keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" -alias "$KEY_ALIAS" > /dev/null 2>&1; then
    echo "✅ Keystore verified successfully"
    
    # Get fingerprint
    FINGERPRINT=$(keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" -alias "$KEY_ALIAS" 2>&1 | grep "SHA1:" | sed 's/.*SHA1: //')
    echo "   SHA1 Fingerprint: $FINGERPRINT"
    echo ""
    echo "📋 Expected fingerprint (from Google Play):"
    echo "   SHA1: 2D:95:7C:D1:61:AD:F9:42:EC:BD:06:91:CF:FC:A3:7C:26:93:5A:5B"
    echo ""
    
    if echo "$FINGERPRINT" | grep -q "2D:95:7C:D1:61:AD:F9:42:EC:BD:06:91:CF:FC:A3:7C:26:93:5A:5B"; then
        echo "✅ Fingerprint matches! This is the correct keystore."
    else
        echo "⚠️  Fingerprint does NOT match. This might not be the correct keystore."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Aborted."
            exit 1
        fi
    fi
else
    echo "❌ Failed to verify keystore. Check password and alias."
    exit 1
fi

# Create key.properties
echo ""
echo "📝 Creating key.properties file..."
cat > "android/key.properties" << EOF
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_NAME
EOF

echo "✅ key.properties created at: android/key.properties"
echo ""
echo "✅ Setup complete! You can now build with: ./scripts/build_merchant_prod_bundle.sh"
echo ""


