#!/bin/bash

# Script to get SHA256 fingerprint from Android keystore
# Usage: ./get_sha256_fingerprint.sh <path-to-keystore> <alias-name>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <path-to-keystore> <alias-name>"
    echo "Example: $0 ./wedy-release-key.jks wedy"
    exit 1
fi

KEYSTORE_PATH=$1
ALIAS_NAME=$2

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "Error: Keystore file not found: $KEYSTORE_PATH"
    exit 1
fi

echo "Getting SHA256 fingerprint from keystore..."
echo "Keystore: $KEYSTORE_PATH"
echo "Alias: $ALIAS_NAME"
echo ""
echo "Please enter keystore password when prompted..."
echo ""

# Run keytool and save output to temp file
TEMP_OUTPUT=$(mktemp)
keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$ALIAS_NAME" > "$TEMP_OUTPUT" 2>&1

# Extract SHA256 from output
SHA256=$(grep -i "SHA256:" "$TEMP_OUTPUT" | head -1 | sed 's/.*SHA256: //' | sed 's/.*sha256: //i' | tr -d ' ' | tr -d ':' | tr '[:upper:]' '[:lower:]')

# Clean up temp file
rm -f "$TEMP_OUTPUT"

if [ -z "$SHA256" ] || [ ${#SHA256} -lt 64 ]; then
    echo ""
    echo "⚠️  Could not automatically extract SHA256 fingerprint."
    echo ""
    echo "Please run this command manually:"
    echo "  keytool -list -v -keystore \"$KEYSTORE_PATH\" -alias \"$ALIAS_NAME\""
    echo ""
    echo "Then:"
    echo "  1. Look for the line that says 'SHA256:'"
    echo "  2. Copy the SHA256 value (the long hex string)"
    echo "  3. Remove all colons (:) and spaces"
    echo "  4. Convert to lowercase"
    echo "  5. Paste it into: backend/app/api/v1/deep_links.py"
    echo "     (Replace 'YOUR_SHA256_FINGERPRINT_HERE')"
    exit 1
fi

echo ""
echo "✓ SHA256 Fingerprint found:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$SHA256"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo "  1. Copy the fingerprint above"
echo "  2. Open: backend/app/api/v1/deep_links.py"
echo "  3. Replace 'YOUR_SHA256_FINGERPRINT_HERE' with the fingerprint"
echo "  4. Restart the backend server"
echo ""
