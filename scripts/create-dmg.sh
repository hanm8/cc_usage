#!/bin/bash

set -e

APP_NAME="ClaudeUsage"
BUILD_DIR="build"
DMG_NAME="$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME Installer"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
TEMP_DMG="$BUILD_DIR/temp.dmg"

# Check if app bundle exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App bundle not found at $APP_PATH"
    exit 1
fi

echo "Creating DMG installer..."

# Remove old DMG if exists
rm -f "$DMG_PATH" "$TEMP_DMG"

# Create temporary DMG
hdiutil create -size 100m -fs HFS+ -volname "$VOLUME_NAME" "$TEMP_DMG"

# Mount the DMG
MOUNT_OUTPUT=$(hdiutil attach "$TEMP_DMG" -nobrowse)
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep Volumes | sed 's/.*\/Volumes/\/Volumes/' | tr -d '\t')

# Copy app to DMG
echo "Copying app to DMG..."
cp -R "$APP_PATH" "$MOUNT_DIR/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "$MOUNT_DIR/Applications"

# Create a README
cat > "$MOUNT_DIR/README.txt" <<EOF
Claude Usage Monitor
====================

Installation:
1. Drag $APP_NAME.app to the Applications folder
2. Open $APP_NAME from Applications
3. The app will appear in your menu bar

Requirements:
- macOS 13.0 or later
- Claude Code CLI installed (run: claude login)

Support:
https://github.com/yourusername/cc_usage
EOF

# Set custom icon positioning (optional, requires ds_store manipulation)
# For now, we'll keep it simple

# Unmount
echo "Finalizing DMG..."
hdiutil detach "$MOUNT_DIR"

# Convert to compressed DMG
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH"

# Clean up
rm -f "$TEMP_DMG"

echo "✅ DMG created successfully at $DMG_PATH"

# Show DMG size
SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo "📦 DMG size: $SIZE"
