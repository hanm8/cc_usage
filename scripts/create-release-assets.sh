#!/bin/bash

set -e

VERSION="${1:-dev}"
BUILD_DIR="build"

echo "Creating release assets for version $VERSION..."

# Create release directory
RELEASE_DIR="$BUILD_DIR/release-$VERSION"
mkdir -p "$RELEASE_DIR"

# Copy main artifacts
echo "Copying main artifacts..."
cp "$BUILD_DIR/ClaudeUsage.dmg" "$RELEASE_DIR/"
cp "$BUILD_DIR/ClaudeUsage.app.zip" "$RELEASE_DIR/"
cp "$BUILD_DIR"/*.sha256 "$RELEASE_DIR/"

# Create installation guide
echo "Creating INSTALL.txt..."
cat > "$RELEASE_DIR/INSTALL.txt" <<'EOF'
# ClaudeUsage Installation Guide

## Quick Install (Recommended)

### Via DMG:
1. Double-click ClaudeUsage.dmg
2. Drag ClaudeUsage.app to Applications folder
3. Open Applications folder
4. Right-click ClaudeUsage.app → Open (first time only)
5. Click "Open" in the security dialog

### Via ZIP:
1. Double-click ClaudeUsage.app.zip to extract
2. Move ClaudeUsage.app to Applications folder
3. Right-click ClaudeUsage.app → Open (first time only)
4. Click "Open" in the security dialog

## First Launch

1. The app icon will appear in your menu bar (top right)
2. Click the icon to see your Claude usage
3. Usage updates automatically every 30 seconds

## Requirements

- macOS 13.0 (Ventura) or later
- Claude Code CLI installed and logged in

If you haven't installed Claude Code CLI:
  npm install -g @anthropic-ai/claude-code
  claude login

## Troubleshooting

### "No credentials found" error:
1. Make sure you've run: claude login
2. Check that ~/.claude/.credentials.json exists
3. Restart the app

### App won't open:
1. Right-click the app → Open (don't double-click)
2. Go to System Settings → Privacy & Security
3. Click "Open Anyway" for ClaudeUsage

### Menu bar icon not showing:
1. Quit and reopen the app
2. Check if app is running in Activity Monitor
3. Try removing and reinstalling

### Usage not updating:
1. Check your internet connection
2. Verify Claude Code credentials: claude login
3. Check menu bar icon for error indicator

## Uninstalling

1. Quit ClaudeUsage from the menu bar (power icon)
2. Delete ClaudeUsage.app from Applications
3. Optional: Remove ~/.claude/.credentials.json

## Support

- Issues: https://github.com/yourusername/cc_usage/issues
- Discussions: https://github.com/yourusername/cc_usage/discussions
- Email: your.email@example.com

## Verification

Verify the download integrity:

  shasum -a 256 -c ClaudeUsage.dmg.sha256
  shasum -a 256 -c ClaudeUsage.app.zip.sha256

Expected checksums are in the .sha256 files.
EOF

# Create changelog entry
echo "Creating CHANGELOG.txt..."
cat > "$RELEASE_DIR/CHANGELOG.txt" <<EOF
ClaudeUsage $VERSION - Release Notes

Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Architecture: Universal (Intel + Apple Silicon)
Minimum macOS: 13.0 (Ventura)

What's Included:
- ClaudeUsage.dmg (DMG installer)
- ClaudeUsage.app.zip (ZIP archive)
- SHA256 checksums for verification
- Installation guide (INSTALL.txt)

For full changelog, see:
https://github.com/yourusername/cc_usage/releases
EOF

# Create README for release
echo "Creating README.txt..."
cat > "$RELEASE_DIR/README.txt" <<'EOF'
# ClaudeUsage - macOS Menu Bar App

Real-time Claude API usage monitoring in your menu bar.

## Features

✓ 5-hour and 7-day usage limits displayed in menu bar
✓ Beautiful detail view with progress bars
✓ Auto-refresh every 30 seconds
✓ Secure credential reading from Claude Code CLI
✓ Automatic retry with exponential backoff
✓ Full VoiceOver accessibility support
✓ Smart error handling with actionable hints
✓ Universal binary (Intel + Apple Silicon)

## Quick Start

1. Install ClaudeUsage.app (see INSTALL.txt)
2. Make sure Claude Code CLI is installed:
   npm install -g @anthropic-ai/claude-code
3. Login to Claude:
   claude login
4. Launch ClaudeUsage from Applications
5. Usage appears in your menu bar

## What You'll See

Menu Bar:
  Clock icon: 5-hour usage (e.g., 45%)
  Chart icon: 7-day usage (e.g., 67%)

Detail View (click menu bar icon):
  - Account name and subscription tier
  - Usage progress bars
  - Time until limits reset
  - Refresh button

## Subscription Tiers

The app displays your subscription:
- FREE: Free tier
- PRO: Claude Pro subscriber
- MAX: Claude Max subscriber
- ENT: Enterprise customer

## System Requirements

- macOS 13.0 (Ventura) or later
- 10 MB disk space
- Claude Code CLI installed

## Privacy & Security

- No data collection or analytics
- Credentials read securely from keychain
- No internet access except Claude API
- Open source (MIT license)

## Source Code

GitHub: https://github.com/yourusername/cc_usage
License: MIT

## Support

- Report bugs: GitHub Issues
- Ask questions: GitHub Discussions
- Email: your.email@example.com

---

Enjoy monitoring your Claude usage!
EOF

# Create a summary manifest
echo "Creating MANIFEST.txt..."
cat > "$RELEASE_DIR/MANIFEST.txt" <<EOF
ClaudeUsage $VERSION - Release Manifest

Files:
------
ClaudeUsage.dmg              - DMG installer (recommended)
ClaudeUsage.app.zip          - ZIP archive (alternative)
ClaudeUsage.dmg.sha256       - DMG checksum
ClaudeUsage.app.zip.sha256   - ZIP checksum
INSTALL.txt                  - Installation instructions
README.txt                   - App overview and features
CHANGELOG.txt                - Version information
MANIFEST.txt                 - This file

Checksums (SHA256):
------------------
$(cat "$BUILD_DIR"/*.sha256)

Build Information:
------------------
Version: $VERSION
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Architecture: Universal (arm64 + x86_64)
macOS Target: 13.0+
Swift Version: $(swift --version | head -1)

Verification:
------------
shasum -a 256 -c ClaudeUsage.dmg.sha256
shasum -a 256 -c ClaudeUsage.app.zip.sha256
EOF

# List all files
echo ""
echo "✅ Release assets created in $RELEASE_DIR/"
echo ""
ls -lh "$RELEASE_DIR/"
echo ""
echo "Total size: $(du -sh "$RELEASE_DIR" | cut -f1)"
