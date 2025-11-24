#!/bin/bash

# Generate app icons for Client and Merchant apps
# Usage: ./scripts/generate_icons.sh [client|merchant|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$MOBILE_DIR"

GENERATE_MODE=${1:-"all"}

echo "🎨 Generating app icons..."
echo ""

if [ "$GENERATE_MODE" = "merchant" ] || [ "$GENERATE_MODE" = "all" ]; then
    echo "📱 Generating Merchant app icons..."
    if [ ! -f "assets/icons/merchant_icon.png" ]; then
        echo "⚠️  Warning: assets/icons/merchant_icon.png not found"
        echo "   Please create a 1024x1024px icon image first"
    else
        flutter pub run flutter_launcher_icons -f flutter_launcher_icons_merchant.yaml
        echo "✅ Merchant app icons generated"
        
        # Move merchant icons to flavor-specific folder
        echo "📦 Moving merchant icons to flavor-specific folder..."
        MERCHANT_RES_DIR="android/app/src/merchant/res"
        MAIN_RES_DIR="android/app/src/main/res"
        
        # Create merchant res directory structure if it doesn't exist
        mkdir -p "$MERCHANT_RES_DIR"
        
        # Copy all mipmap density folders
        MIPMAP_DENSITIES=("mipmap-mdpi" "mipmap-hdpi" "mipmap-xhdpi" "mipmap-xxhdpi" "mipmap-xxxhdpi")
        
        for density in "${MIPMAP_DENSITIES[@]}"; do
            SRC_DIR="$MAIN_RES_DIR/$density"
            DST_DIR="$MERCHANT_RES_DIR/$density"
            
            if [ -d "$SRC_DIR" ]; then
                mkdir -p "$DST_DIR"
                
                # Copy regular launcher icon
                if [ -f "$SRC_DIR/ic_launcher.png" ]; then
                    cp "$SRC_DIR/ic_launcher.png" "$DST_DIR/ic_launcher.png"
                    echo "  ✅ Copied $density/ic_launcher.png"
                fi
                
                # Copy adaptive icon files if they exist
                if [ -f "$SRC_DIR/ic_launcher_foreground.png" ]; then
                    cp "$SRC_DIR/ic_launcher_foreground.png" "$DST_DIR/ic_launcher_foreground.png"
                    echo "  ✅ Copied $density/ic_launcher_foreground.png"
                fi
                if [ -f "$SRC_DIR/ic_launcher_background.png" ]; then
                    cp "$SRC_DIR/ic_launcher_background.png" "$DST_DIR/ic_launcher_background.png"
                    echo "  ✅ Copied $density/ic_launcher_background.png"
                fi
            fi
        done
        
        echo "✅ Merchant icons moved to flavor-specific folder"
    fi
    echo ""
fi

if [ "$GENERATE_MODE" = "client" ] || [ "$GENERATE_MODE" = "all" ]; then
    echo "📱 Generating Client app icons..."
    if [ ! -f "assets/icons/client_icon.png" ]; then
        echo "⚠️  Warning: assets/icons/client_icon.png not found"
        echo "   Please create a 1024x1024px icon image first"
    else
        flutter pub run flutter_launcher_icons -f flutter_launcher_icons_client.yaml
        echo "✅ Client app icons generated"
    fi
    echo ""
fi

echo "✅ Icon generation completed!"
echo ""
echo "Next steps:"
echo "1. Verify icons in android/app/src/main/res/mipmap-*/ (client app)"
echo "2. Verify icons in android/app/src/merchant/res/mipmap-*/ (merchant app)"
echo "3. Rebuild the app to see new icons"

