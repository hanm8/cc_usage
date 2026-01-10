#!/bin/bash

set -e

APP_NAME="ClaudeUsage"
VERSION="1.0.0"
BUNDLE_ID="com.claude.usage"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean and create directories
echo "Creating app bundle structure..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create app icon
echo "Creating app icon..."
chmod +x ./scripts/create-icns.sh
./scripts/create-icns.sh

# Copy binary
echo "Copying binary..."
# Try different possible locations
if [ -f ".build/apple/Products/Release/$APP_NAME" ]; then
    cp ".build/apple/Products/Release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
elif [ -f ".build/release/$APP_NAME" ]; then
    cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
else
    echo "❌ Error: Could not find built binary"
    echo "Searched in:"
    echo "  - .build/apple/Products/Release/$APP_NAME"
    echo "  - .build/release/$APP_NAME"
    exit 1
fi
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy app icon
echo "Copying app icon..."
cp "$BUILD_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025. All rights reserved.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Create ZIP archive
echo "Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r "$APP_NAME.app.zip" "$APP_NAME.app"
cd ..

echo "✅ App bundle created successfully at $APP_DIR"
echo "✅ ZIP archive created at $BUILD_DIR/$APP_NAME.app.zip"
