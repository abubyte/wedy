#!/bin/bash

# Script to generate Android signing keystore
# Usage: ./scripts/generate_keystore.sh [keystore_name]

set -e

KEYSTORE_NAME=${1:-"wedy-release-key"}
KEYSTORE_PATH="android/app/$KEYSTORE_NAME.jks"
KEYSTORE_PROPERTIES="android/key.properties"

echo "🔐 Generating Android signing keystore..."
echo ""

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore already exists at: $KEYSTORE_PATH"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Keystore generation cancelled."
        exit 1
    fi
    rm "$KEYSTORE_PATH"
fi

# Prompt for keystore details
echo "Please provide the following information for your keystore:"
echo ""

read -p "Key alias (default: wedy-key): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-wedy-key}

read -p "Validity in years (default: 25): " VALIDITY
VALIDITY=${VALIDITY:-25}

read -sp "Keystore password: " KEYSTORE_PASSWORD
echo ""

read -sp "Key password (press Enter to use same as keystore password): " KEY_PASSWORD
echo ""
KEY_PASSWORD=${KEY_PASSWORD:-$KEYSTORE_PASSWORD}

# Generate keystore
echo ""
echo "Generating keystore..."
keytool -genkey -v -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $((VALIDITY * 365)) \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Wedy, OU=Development, O=Wedy, L=Tashkent, ST=Tashkent, C=UZ"

echo ""
echo "✅ Keystore generated successfully at: $KEYSTORE_PATH"
echo ""

# Create key.properties file
echo "Creating key.properties file..."
cat > "$KEYSTORE_PROPERTIES" << EOF
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_NAME.jks
EOF

echo "✅ key.properties created at: $KEYSTORE_PROPERTIES"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "   1. Keep your keystore file ($KEYSTORE_PATH) secure and backed up"
echo "   2. Never commit the keystore or key.properties to version control"
echo "   3. Store the passwords in a secure password manager"
echo "   4. If you lose the keystore, you won't be able to update your app on Google Play"
echo ""
echo "📝 Next steps:"
echo "   1. The build.gradle.kts has been configured to use this keystore"
echo "   2. You can now build production bundles with: ./scripts/build_merchant_prod_bundle.sh"
echo ""

