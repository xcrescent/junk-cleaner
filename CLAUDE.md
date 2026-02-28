# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build              # Debug build
swift build -c release   # Release build
swift run                # Build and launch the app
```

No external dependencies — uses only Foundation, AppKit, and SwiftUI via Swift Package Manager. No test suite exists yet.

## Architecture

MVVM macOS app (SwiftUI, macOS 14+). Single executable target.

**Data flow:** `JunkCleanerApp` (@main) → `JunkCleanerViewModel` (@MainActor ObservableObject) → `ScannerService` / `CleanerService` → Views observe `@Published` state.

**AppState lifecycle:** `idle` → `scanning(progress)` → `scanned` → `cleaning(progress)` → `cleaned(freedBytes, trashedCount, permanentlyDeletedCount)` or `error(message)`.

### Key abstractions

- **ScanMode** (5 cases) drives how each junk category is discovered: `directorySize`, `filesOlderThan(days:)`, `recursiveFileSearch(name:)`, `recursiveDirectorySearch(name:)`, `universalBinaries`. Adding a new scan mode requires: adding the enum case, handling it in `ScannerService.scan(category:)`, and handling it in `CleanerService.clean(category:mode:)`.

- **DeletionMode** — `.moveToTrash` (default, uses `FileManager.trashItem`) or `.deletePermanently` (uses `removeItem`). Trash category always forces permanent deletion. Universal binaries always use `lipo -remove x86_64` regardless of deletion mode.

- **PermissionStatus** — per-category permission tracking (`.accessible`, `.partialAccess(restrictedPaths:)`, `.denied`). Scan helpers `throw` on permission errors; `scan(category:)` catches them and populates this field.

### Adding a new junk category

1. Add a `JunkCategory(...)` entry in `ScannerService.buildCategories()` with the appropriate `ScanMode`
2. If using an existing scan mode, no other changes needed
3. If a new scan mode is needed: add the enum case, add a scan method in `ScannerService`, add clean handling in `CleanerService`

### Binary thinning (universal binaries)

`ScannerService` uses `Process` to run `/usr/bin/lipo` for architecture detection and size calculation. `CleanerService.thinBinary(at:)` does atomic replacement: `lipo -remove x86_64` → temp file → remove original → move temp to original. The `isUniversalWithIntel` check runs `lipo -archs` per binary.

## Key conventions

- All `@Published` mutations happen on `@MainActor` (the ViewModel is `@MainActor`)
- Size calculations use `totalFileAllocatedSizeKey` (not `fileSizeKey`) for accurate disk usage
- Scan helpers that access directories should `throw` to enable permission error detection
- `CleanerService` returns `CleanResult` (not just bytes) with per-category error/count breakdown
- Category `isSelected` controls both scanning and cleaning — only selected categories are scanned
