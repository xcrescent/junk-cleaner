# Junk Cleaner

A macOS app that scans and removes junk files to free up disk space — targeting system caches, developer tool caches, browser caches, and more.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ or Swift 5.9+ (for building from source)

## Build & Run

```bash
cd junk-cleaner

# Build and run
swift run

# Or build only
swift build
```

Alternatively, open `Package.swift` in Xcode and press **Cmd+R**.

## Usage

### Workflow

1. **Scan** — Click the Scan button to discover junk files across all categories. Each category updates progressively as it completes.
2. **Review** — Expand any category to see individual items sorted by size. Toggle checkboxes to select or deselect categories.
3. **Clean** — Click Clean Selected to delete the chosen junk. A summary shows how much space was freed.

### Junk Categories

| Category | Target | Scan Mode |
|----------|--------|-----------|
| System Caches | `~/Library/Caches/` | Full directory |
| System Logs | `~/Library/Logs/` | Full directory |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData/` | Full directory |
| Homebrew Cache | `~/Library/Caches/Homebrew/` | Full directory |
| npm Cache | `~/.npm/_cacache/` | Full directory |
| Yarn Cache | `~/Library/Caches/Yarn/` | Full directory |
| pnpm Cache | `~/Library/pnpm-store/` | Full directory |
| Browser Caches | Safari, Chrome, Firefox | Full directory |
| Docker Data | `~/Library/Containers/com.docker.docker/Data/` | Full directory |
| Trash | `~/.Trash/` | Full directory |
| .DS_Store Files | Home, Desktop, Documents, Downloads | Recursive file search |
| Old Downloads | `~/Downloads/` (>30 days old) | Age-filtered |

Non-existent paths are silently skipped — the app only shows categories with data on your system.

## How It Works

- **Scanning** uses `FileManager` with `totalFileAllocatedSizeKey` for accurate disk usage (accounts for block allocation, not just logical file size)
- **Cleaning** deletes the *contents* of directories, not the directories themselves — the OS expects directories like `~/Library/Caches/` to exist
- For filtered categories (Old Downloads, .DS_Store), only the specific matched items are deleted
- All file operations run on background threads via `async/await` to keep the UI responsive

## Project Structure

```
junk-cleaner/
├── Package.swift
└── JunkCleaner/
    ├── App/
    │   └── JunkCleanerApp.swift           # @main entry point (WindowGroup)
    ├── Models/
    │   └── JunkCategory.swift             # JunkCategory, JunkItem, ScanMode
    ├── Services/
    │   ├── ScannerService.swift           # Directory scanning & size calculation
    │   └── CleanerService.swift           # File/directory deletion
    ├── ViewModels/
    │   └── JunkCleanerViewModel.swift     # Central state coordinator
    ├── Views/
    │   ├── ContentView.swift              # Main window layout
    │   ├── CategoryRowView.swift          # Category row with checkbox & expand
    │   └── CategoryDetailView.swift       # Expanded item list
    └── Assets.xcassets/                   # App icon assets
```

## Architecture

The app follows **MVVM**:

- **ScannerService** builds the category list and calculates sizes using three scan modes: full directory, age-filtered files, and recursive file search
- **CleanerService** handles safe deletion — contents only for directories, specific items for filtered categories
- **JunkCleanerViewModel** (`@MainActor ObservableObject`) owns the app state and coordinates scanning, cleaning, and UI updates
- **AppState** enum tracks the lifecycle: idle → scanning → scanned → cleaning → cleaned

## Permissions

| Permission | Required | Why |
|------------|----------|-----|
| File system access | Automatic | Reads/deletes files in user-owned directories (`~/Library/`, `~/.Trash/`, etc.) |
| Full Disk Access | Optional | May be needed for some protected caches (e.g., Safari). Grant in **System Settings > Privacy & Security > Full Disk Access** |
