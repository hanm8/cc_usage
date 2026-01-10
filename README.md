# Claude Usage - macOS Menu Bar App

Native Swift menu bar app showing Claude Code 5-hour and 7-day limits in real-time.

## Installation

### Download Release (Recommended)

1. Go to [Releases](https://github.com/hanm8/cc_usage/releases/latest)
2. **Choose your architecture:**
   - **Apple Silicon** (M1/M2/M3/M4): Download `ClaudeUsage-arm64.dmg`
   - **Intel**: Download `ClaudeUsage-intel.dmg`
3. Open the DMG and drag **ClaudeUsage.app** to Applications
4. **First launch** (app is unsigned, run once):
   ```bash
   xattr -cr /Applications/ClaudeUsage.app
   ```
5. Open from Applications - the app will appear in your menu bar

**Not sure which version?** Click  → About This Mac:
- "Chip: Apple M1/M2/M3/M4" = Download ARM64
- "Processor: Intel" = Download Intel

**Each release includes:**
- `ClaudeUsage-arm64.dmg` - ARM64 DMG installer (Apple Silicon)
- `ClaudeUsage-arm64.app.zip` - ARM64 ZIP archive
- `ClaudeUsage-intel.dmg` - Intel DMG installer (x86_64)
- `ClaudeUsage-intel.app.zip` - Intel ZIP archive
- `*.sha256` - Checksums for verification

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
# Release build (current architecture)
swift build -c release

# Build for specific architecture
swift build -c release --arch arm64   # Apple Silicon
swift build -c release --arch x86_64  # Intel
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
# Build for ARM64 (Apple Silicon)
swift build -c release --arch arm64
mkdir -p .build/release-arm64
cp .build/release/ClaudeUsage .build/release-arm64/
./scripts/create-app-bundle-arch.sh arm64
./scripts/create-dmg-arch.sh arm64

# Build for Intel (x86_64)
swift build -c release --arch x86_64
mkdir -p .build/release-intel
cp .build/release/ClaudeUsage .build/release-intel/
./scripts/create-app-bundle-arch.sh intel
./scripts/create-dmg-arch.sh intel
```

The outputs will be in architecture-specific directories:
- `build-arm64/` - ARM64 app bundle, ZIP, and DMG
- `build-intel/` - Intel app bundle, ZIP, and DMG

#### Automated Release (GitHub Actions)

1. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically:
   - Build separate ARM64 and Intel binaries
   - Create architecture-specific app bundles
   - Generate DMG installers for each architecture
   - Create GitHub release with all artifacts

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
