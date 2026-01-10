#!/bin/bash

set -e

ARCH="${1:-arm64}"  # arm64 or intel
APP_NAME="ClaudeUsage"
VERSION="1.0.0"
BUNDLE_ID="com.claude.usage"
BUILD_DIR="build-${ARCH}"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Map architecture names
if [[ "$ARCH" == "intel" ]]; then
    SWIFT_ARCH="x86_64"
    ARCH_DISPLAY="Intel"
elif [[ "$ARCH" == "arm64" ]]; then
    SWIFT_ARCH="arm64"
    ARCH_DISPLAY="Apple Silicon"
else
    echo "❌ Invalid architecture: $ARCH (use 'arm64' or 'intel')"
    exit 1
fi

echo "Creating $ARCH_DISPLAY app bundle for $ARCH..."

# Clean and create directories
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create app icon (shared)
if [ ! -f "build/AppIcon.icns" ]; then
    echo "Creating app icon..."
    chmod +x ./scripts/create-icns.sh
    ./scripts/create-icns.sh
fi

# Copy binary from architecture-specific location
echo "Copying $ARCH binary..."
BINARY_PATH=".build/release-${ARCH}/ClaudeUsage"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Could not find $ARCH binary at $BINARY_PATH"
    exit 1
fi

cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Verify architecture
echo "Verifying binary architecture..."
file "$MACOS_DIR/$APP_NAME"
lipo -info "$MACOS_DIR/$APP_NAME" || true

# Copy app icon
echo "Copying app icon..."
cp "build/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

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

# Ad-hoc code sign (helps prevent "damaged app" errors)
echo "Ad-hoc signing app bundle..."
codesign --force --deep --sign - "$APP_DIR"

# Create ZIP archive
echo "Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r "$APP_NAME-${ARCH}.app.zip" "$APP_NAME.app"
cd ..

echo "✅ $ARCH_DISPLAY app bundle created at $APP_DIR"
echo "✅ ZIP archive created at $BUILD_DIR/$APP_NAME-${ARCH}.app.zip"
