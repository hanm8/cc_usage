# Claude Usage - macOS Menu Bar App

Native Swift menu bar app showing Claude Code 5-hour and 7-day limits in real-time.

## Installation

### Download Release (Recommended)

1. Go to [Releases](https://github.com/yourusername/cc_usage/releases/latest)
2. Download **ClaudeUsage.dmg** (also grab `INSTALL.txt` for detailed instructions)
3. Open the DMG and drag **ClaudeUsage.app** to Applications
4. Launch from Applications folder (right-click → Open first time)
5. The app will appear in your menu bar

**Each release includes:**
- `ClaudeUsage.dmg` - DMG installer
- `ClaudeUsage.app.zip` - ZIP archive
- `*.sha256` - Checksums for verification
- `INSTALL.txt` - Detailed installation guide
- `README.txt` - App overview
- `CHANGELOG.txt` - Version notes
- `MANIFEST.txt` - Complete file listing

### Build from Source

```bash
swift build -c release
.build/release/ClaudeUsage
```

## Features

- 📊 Real-time usage display in menu bar: `5h:X% • 7d:Y%`
- 🎨 Beautiful detail view with progress bars
- 🔄 Auto-refreshes every 30 seconds
- 🔐 Secure credential reading from `~/.claude/.credentials.json`
- ⚡ Automatic retry with exponential backoff
- ♿ Full VoiceOver accessibility support
- 🎯 Smart error handling with actionable hints

## Requirements

- macOS 13.0 or later
- Claude Code CLI installed and authenticated
  ```bash
  claude login
  ```

## Development

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Universal binary (Intel + Apple Silicon)
swift build -c release --arch arm64 --arch x86_64
```

### Running

```bash
# Debug
.build/debug/ClaudeUsage

# Release
.build/release/ClaudeUsage
```

### Creating Release Builds

#### Manual Build

```bash
# Build app bundle
./scripts/create-app-bundle.sh

# Create DMG installer
./scripts/create-dmg.sh
```

The outputs will be in the `build/` directory:
- `ClaudeUsage.app` - Application bundle
- `ClaudeUsage.app.zip` - ZIP archive
- `ClaudeUsage.dmg` - DMG installer

#### Automated Release (GitHub Actions)

1. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically:
   - Build universal binary (Intel + Apple Silicon)
   - Create app bundle
   - Generate DMG installer
   - Create GitHub release with artifacts

## Architecture

### Core Components

- **APIService** (Actor) - Thread-safe API client with retry logic
- **CredentialService** (Actor) - Secure credential management with caching
- **UsageViewModel** - SwiftUI view model with error handling
- **ContentView** - Main UI with accessibility support

### Error Handling

The app features comprehensive error handling:
- Network errors with auto-retry (3 attempts, exponential backoff)
- Token expiration detection
- Credential validation
- Rate limiting awareness
- User-friendly error messages with action hints

## License

MIT

## Contributing

Pull requests welcome!
