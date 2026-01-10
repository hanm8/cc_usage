# Claude Usage

macOS menu bar app showing Claude Code usage limits in real-time.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Installation

1. Download from [Releases](https://github.com/hanm8/cc_usage/releases/latest):
   - **Apple Silicon** (M1/M2/M3/M4): `ClaudeUsage-arm64.dmg`
   - **Intel**: `ClaudeUsage-intel.dmg`

2. Open DMG and drag to Applications

3. Open from Applications

> **Which version?**  → About This Mac → "Chip: M1/M2/M3/M4" = ARM64, "Processor: Intel" = Intel

## Requirements

- macOS 13.0+
- Claude Code CLI authenticated (`claude login`)

## Features

- Real-time 5-hour and 7-day limit display
- Auto-refresh every 30 seconds
- Reset time countdown
- Menu bar integration

## Build from Source

```bash
swift build -c release
.build/release/ClaudeUsage
```

## License

MIT
