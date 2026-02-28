import Foundation

final class CleanerService {
    private let fileManager = FileManager.default

    func clean(category: JunkCategory, mode: DeletionMode) async -> CleanResult {
        var freedBytes: Int64 = 0
        var trashedCount = 0
        var permanentlyDeletedCount = 0
        var errors: [String] = []

        switch category.scanMode {
        case .directorySize:
            for path in category.paths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                let r = deleteContents(of: path, mode: mode)
                freedBytes += r.freed
                trashedCount += r.trashedCount
                permanentlyDeletedCount += r.permanentlyDeletedCount
                errors.append(contentsOf: r.errors)
            }

        case .filesOlderThan, .recursiveFileSearch, .recursiveDirectorySearch:
            for item in category.items {
                let r = removeSingleItem(at: item.path, mode: mode)
                freedBytes += r.freed
                trashedCount += r.trashedCount
                permanentlyDeletedCount += r.permanentlyDeletedCount
                errors.append(contentsOf: r.errors)
            }
        }

        return CleanResult(
            categoryID: category.id,
            categoryName: category.name,
            freedBytes: freedBytes,
            trashedCount: trashedCount,
            permanentlyDeletedCount: permanentlyDeletedCount,
            errors: errors
        )
    }

    // MARK: - Private

    private struct DeletionResult {
        var freed: Int64 = 0
        var trashedCount: Int = 0
        var permanentlyDeletedCount: Int = 0
        var errors: [String] = []
    }

    private func deleteContents(of directory: URL, mode: DeletionMode) -> DeletionResult {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil, options: []
        ) else { return DeletionResult() }

        var result = DeletionResult()
        for item in contents {
            let r = removeSingleItem(at: item, mode: mode)
            result.freed += r.freed
            result.trashedCount += r.trashedCount
            result.permanentlyDeletedCount += r.permanentlyDeletedCount
            result.errors.append(contentsOf: r.errors)
        }
        return result
    }

    private func removeSingleItem(at url: URL, mode: DeletionMode) -> DeletionResult {
        guard fileManager.fileExists(atPath: url.path) else { return DeletionResult() }

        let size = ScannerService.allocatedSize(of: url)
        var result = DeletionResult()

        if mode == .moveToTrash {
            do {
                var trashedURL: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)
                result.freed = size
                result.trashedCount = 1
            } catch {
                // Fallback to permanent deletion (e.g., items already in Trash)
                do {
                    try fileManager.removeItem(at: url)
                    result.freed = size
                    result.permanentlyDeletedCount = 1
                } catch {
                    result.errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } else {
            do {
                try fileManager.removeItem(at: url)
                result.freed = size
                result.permanentlyDeletedCount = 1
            } catch {
                result.errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return result
    }
}
