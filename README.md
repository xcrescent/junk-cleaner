# Junk Cleaner

A macOS app that scans and removes junk files to free up disk space — targeting system caches, developer tool caches, browser caches, universal binary bloat, and more.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-orange) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-blue)

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (for Intel code stripping feature)
- Xcode 15+ or Swift 5.9+ (for building from source)

## Build & Run

```bash
cd junk-cleaner

# Build and run
swift run

# Or build a release and install to /Applications
swift build -c release
mkdir -p "Junk Cleaner.app/Contents/MacOS"
cp .build/release/JunkCleaner "Junk Cleaner.app/Contents/MacOS/JunkCleaner"
cp JunkCleaner/Info.plist "Junk Cleaner.app/Contents/Info.plist"
cp -R "Junk Cleaner.app" /Applications/
```

Alternatively, open `Package.swift` in Xcode and press **Cmd+R**.

## Usage

### Workflow

1. **Select** — Toggle checkboxes to choose which categories to scan. Only selected categories are scanned.
2. **Scan** — Click Scan to discover junk files. Each category updates progressively with color-coded sizes (green < 100 MB, orange < 1 GB, red >= 1 GB).
3. **Review** — Expand any category to see individual items sorted by size. Click the arrow button to reveal an item in Finder.
4. **Clean** — Click Clean Selected. A confirmation sheet shows the category breakdown and lets you choose between **Move to Trash** (default, recoverable) or **Delete Permanently**.

### Junk Categories

| Category | Target | Scan Mode |
|----------|--------|-----------|
| System Caches | `~/Library/Caches/` | Full directory |
| System Logs | `~/Library/Logs/` | Full directory |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData/` | Full directory |
| Xcode Simulators | `~/Library/Developer/CoreSimulator/Devices/` | Full directory |
| Homebrew Cache | `~/Library/Caches/Homebrew/` | Full directory |
| npm Cache | `~/.npm/_cacache/` | Full directory |
| Yarn Cache | `~/Library/Caches/Yarn/` | Full directory |
| pnpm Cache | `~/Library/pnpm-store/` | Full directory |
| CocoaPods Cache | `~/Library/Caches/CocoaPods/` | Full directory |
| Gradle Cache | `~/.gradle/caches/` | Full directory |
| Browser Caches | Safari, Chrome, Firefox | Full directory |
| Docker Data | `~/Library/Containers/com.docker.docker/Data/` | Full directory |
| Trash | `~/.Trash/` | Full directory |
| Intel Code in Apps | `/Applications/*.app` universal binaries | `lipo` analysis |
| node_modules | ~/Projects, ~/Developer, ~/Desktop, ~/Documents | Recursive directory search |
| .DS_Store Files | Home, Desktop, Documents, Downloads | Recursive file search |
| Old Downloads | `~/Downloads/` (>30 days old) | Age-filtered |

Non-existent paths are silently skipped. Categories with permission issues show a warning icon.

### Intel Code Stripping

On Apple Silicon Macs, many apps ship as universal binaries containing both arm64 and x86_64 code. The **Intel Code in Apps** category:

- Scans `/Applications` for universal (fat) Mach-O binaries
- Uses `lipo -detailed_info` to calculate the exact x86_64 slice size per app
- When cleaned, uses `lipo -remove x86_64` to thin each binary in-place
- **Deselected by default** since it's irreversible — enable it manually when ready

This can reclaim several gigabytes depending on your installed apps.

## How It Works

- **Scanning** uses `FileManager` with `totalFileAllocatedSizeKey` for accurate disk usage (accounts for block allocation, not just logical file size). Only selected categories are scanned.
- **Cleaning** offers two modes: **Move to Trash** (default, recoverable) or **Delete Permanently**. Trash items always use permanent deletion since they're already in the trash.
- For directory categories, contents are deleted but the directory itself is preserved — the OS expects directories like `~/Library/Caches/` to exist.
- For filtered categories (Old Downloads, .DS_Store, node_modules), only the specific matched items are deleted.
- Universal binary thinning uses `lipo -remove x86_64` with a temp file + atomic swap to avoid corruption.
- All file operations run on background threads via `async/await` to keep the UI responsive.
- Permission errors (EACCES) are detected per-path and surfaced with warning icons. A **Grant Full Disk Access** button opens System Settings directly.

## Project Structure

```
junk-cleaner/
├── Package.swift
└── JunkCleaner/
    ├── App/
    │   └── JunkCleanerApp.swift           # @main entry point (WindowGroup)
    ├── Models/
    │   └── JunkCategory.swift             # JunkCategory, JunkItem, ScanMode, DeletionMode
    ├── Services/
    │   ├── ScannerService.swift           # Directory scanning, size calculation, lipo analysis
    │   └── CleanerService.swift           # Deletion, trash, binary thinning
    ├── ViewModels/
    │   └── JunkCleanerViewModel.swift     # Central state coordinator
    ├── Views/
    │   ├── ContentView.swift              # Main window layout
    │   ├── CategoryRowView.swift          # Category row with checkbox, size, permission icon
    │   ├── CategoryDetailView.swift       # Scrollable item list with Reveal in Finder
    │   └── CleanConfirmationView.swift    # Confirmation sheet with deletion mode picker
    └── Assets.xcassets/                   # App icon (orange gradient, broom + sparkles)
```

## Architecture

The app follows **MVVM**:

- **ScannerService** builds the category list and calculates sizes using five scan modes: full directory, age-filtered files, recursive file search, recursive directory search, and universal binary analysis via `lipo`
- **CleanerService** handles safe deletion with two modes (trash / permanent), plus binary thinning for universal binaries
- **JunkCleanerViewModel** (`@MainActor ObservableObject`) owns the app state and coordinates scanning, cleaning, confirmation flow, and UI updates
- **AppState** enum tracks the lifecycle: idle → scanning → scanned → cleaning → cleaned

## Permissions

| Permission | Required | Why |
|------------|----------|-----|
| File system access | Automatic | Reads/deletes files in user-owned directories (`~/Library/`, `~/.Trash/`, etc.) |
| Full Disk Access | Optional | Needed for protected caches (e.g., Safari). Grant in **System Settings > Privacy & Security > Full Disk Access**. The app shows a button to open this directly. |
