#!/bin/bash

set -e

ASSETS_DIR="ClaudeUsage/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="build/AppIcon.iconset"
OUTPUT_ICNS="build/AppIcon.icns"

echo "Creating .icns from Assets.xcassets..."

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Copy and rename icons according to iconset conventions
cp "$ASSETS_DIR/icon_16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$ASSETS_DIR/icon_32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ASSETS_DIR/icon_32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$ASSETS_DIR/icon_64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ASSETS_DIR/icon_128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$ASSETS_DIR/icon_256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ASSETS_DIR/icon_256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$ASSETS_DIR/icon_512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ASSETS_DIR/icon_512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$ASSETS_DIR/icon_1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# Convert iconset to icns
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# Clean up
rm -rf "$ICONSET_DIR"

echo "✅ Created $OUTPUT_ICNS"
