import Foundation

final class ScannerService {
    private let fileManager = FileManager.default

    func buildCategories() -> [JunkCategory] {
        let home = fileManager.homeDirectoryForCurrentUser

        return [
            JunkCategory(
                id: "system_caches",
                name: "System Caches",
                description: "~/Library/Caches/",
                icon: "internaldrive",
                paths: [home.appending(path: "Library/Caches")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "system_logs",
                name: "System Logs",
                description: "~/Library/Logs/",
                icon: "doc.text",
                paths: [home.appending(path: "Library/Logs")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "xcode_deriveddata",
                name: "Xcode DerivedData",
                description: "~/Library/Developer/Xcode/DerivedData/",
                icon: "hammer",
                paths: [home.appending(path: "Library/Developer/Xcode/DerivedData")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "homebrew_cache",
                name: "Homebrew Cache",
                description: "~/Library/Caches/Homebrew/",
                icon: "mug",
                paths: [home.appending(path: "Library/Caches/Homebrew")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "npm_cache",
                name: "npm Cache",
                description: "~/.npm/_cacache/",
                icon: "shippingbox",
                paths: [home.appending(path: ".npm/_cacache")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "yarn_cache",
                name: "Yarn Cache",
                description: "~/Library/Caches/Yarn/",
                icon: "shippingbox",
                paths: [home.appending(path: "Library/Caches/Yarn")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "pnpm_cache",
                name: "pnpm Cache",
                description: "~/Library/pnpm-store/",
                icon: "shippingbox",
                paths: [home.appending(path: "Library/pnpm-store")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "browser_caches",
                name: "Browser Caches",
                description: "Safari, Chrome, Firefox caches",
                icon: "globe",
                paths: [
                    home.appending(path: "Library/Caches/com.apple.Safari"),
                    home.appending(path: "Library/Caches/Google/Chrome"),
                    home.appending(path: "Library/Caches/Firefox/Profiles"),
                ],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "docker",
                name: "Docker Data",
                description: "~/Library/Containers/com.docker.docker/Data/",
                icon: "cube.box",
                paths: [home.appending(path: "Library/Containers/com.docker.docker/Data")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "trash",
                name: "Trash",
                description: "~/.Trash/",
                icon: "trash",
                paths: [home.appending(path: ".Trash")],
                scanMode: .directorySize
            ),
            JunkCategory(
                id: "ds_store",
                name: ".DS_Store Files",
                description: "Finder metadata files in common directories",
                icon: "doc.badge.gearshape",
                paths: [
                    home,
                    home.appending(path: "Desktop"),
                    home.appending(path: "Documents"),
                    home.appending(path: "Downloads"),
                ],
                scanMode: .recursiveFileSearch(name: ".DS_Store")
            ),
            JunkCategory(
                id: "old_downloads",
                name: "Old Downloads",
                description: "~/Downloads/ files older than 30 days",
                icon: "arrow.down.circle",
                paths: [home.appending(path: "Downloads")],
                scanMode: .filesOlderThan(days: 30)
            ),
        ]
    }

    func scan(category: JunkCategory) async -> JunkCategory {
        var result = category
        var items: [JunkItem] = []
        var totalSize: Int64 = 0

        switch category.scanMode {
        case .directorySize:
            for path in category.paths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                let (dirItems, dirSize) = scanDirectory(at: path)
                items.append(contentsOf: dirItems)
                totalSize += dirSize
            }

        case .filesOlderThan(let days):
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            for path in category.paths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                let (oldItems, oldSize) = scanForOldFiles(at: path, olderThan: cutoffDate)
                items.append(contentsOf: oldItems)
                totalSize += oldSize
            }

        case .recursiveFileSearch(let name):
            for path in category.paths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                let (foundItems, foundSize) = scanForFiles(named: name, in: path)
                items.append(contentsOf: foundItems)
                totalSize += foundSize
            }
        }

        result.items = items
        result.size = totalSize
        result.isScanned = true
        return result
    }

    // MARK: - Private Helpers

    private func scanDirectory(at url: URL) -> ([JunkItem], Int64) {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return ([], 0) }

        var items: [JunkItem] = []
        var totalSize: Int64 = 0

        for itemURL in contents {
            let itemSize = Self.allocatedSize(of: itemURL)
            let modDate = (try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate

            items.append(JunkItem(name: itemURL.lastPathComponent, path: itemURL, size: itemSize, modifiedDate: modDate))
            totalSize += itemSize
        }

        return (items.sorted { $0.size > $1.size }, totalSize)
    }

    private func scanForOldFiles(at url: URL, olderThan cutoff: Date) -> ([JunkItem], Int64) {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .contentModificationDateKey],
            options: []
        ) else { return ([], 0) }

        var items: [JunkItem] = []
        var totalSize: Int64 = 0

        for itemURL in contents {
            guard let values = try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = values.contentModificationDate,
                  modDate < cutoff else { continue }

            let itemSize = Self.allocatedSize(of: itemURL)
            items.append(JunkItem(name: itemURL.lastPathComponent, path: itemURL, size: itemSize, modifiedDate: modDate))
            totalSize += itemSize
        }

        return (items.sorted { $0.size > $1.size }, totalSize)
    }

    private func scanForFiles(named name: String, in directory: URL) -> ([JunkItem], Int64) {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [.skipsPackageDescendants]
        ) else { return ([], 0) }

        var items: [JunkItem] = []
        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard fileURL.lastPathComponent == name else { continue }
            let itemSize = Self.allocatedSize(of: fileURL)
            let displayName = fileURL.path.replacingOccurrences(
                of: fileManager.homeDirectoryForCurrentUser.path,
                with: "~"
            )
            items.append(JunkItem(name: displayName, path: fileURL, size: itemSize, modifiedDate: nil))
            totalSize += itemSize
        }

        return (items, totalSize)
    }

    static func allocatedSize(of url: URL) -> Int64 {
        let fm = FileManager.default
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]) else { return 0 }

        if values.isDirectory == true {
            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                options: []
            ) else { return 0 }

            var total: Int64 = 0
            for case let fileURL as URL in enumerator {
                if let fileValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]) {
                    total += Int64(fileValues.totalFileAllocatedSize ?? 0)
                }
            }
            return total
        } else {
            let fileValues = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            return Int64(fileValues?.totalFileAllocatedSize ?? 0)
        }
    }
}
