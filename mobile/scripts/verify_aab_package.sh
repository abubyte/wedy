#!/bin/bash

# Script to verify the package name in an AAB file
# Usage: ./scripts/verify_aab_package.sh [path_to_aab]

set -e

AAB_PATH=${1:-"build/app/outputs/bundle/merchantProdRelease/app-merchant-prod-release.aab"}

if [ ! -f "$AAB_PATH" ]; then
    echo "❌ AAB file not found at: $AAB_PATH"
    exit 1
fi

echo "🔍 Verifying package name in AAB: $AAB_PATH"
echo ""

# Try to extract and check the package name
# Method 1: Check merged manifest if available
if [ -d "build/app/intermediates/merged_manifests/merchantProdRelease" ]; then
    echo "📋 Checking merged manifest:"
    find build/app/intermediates/merged_manifests/merchantProdRelease -name "AndroidManifest.xml" 2>/dev/null | head -1 | xargs grep -h "package=" 2>/dev/null || echo "   No manifest found"
    echo ""
fi

# Method 2: Try to use aapt if available
if command -v aapt &> /dev/null; then
    echo "📦 Checking with aapt:"
    aapt dump badging "$AAB_PATH" 2>/dev/null | grep -E "^package:" | head -1 || echo "   Could not read with aapt"
    echo ""
fi

# Method 3: Check build configuration
echo "⚙️  Build configuration:"
echo "   Expected package for merchant: uz.wedy.business"
echo "   Expected package for client: uz.wedy.app"
echo ""

# Method 4: List all built variants
echo "📁 Available build variants:"
find build/app/outputs/bundle -name "*.aab" 2>/dev/null | while read aab; do
    echo "   - $aab"
done
echo ""

echo "✅ Verification complete"

