import Foundation

final class CleanerService {
    private let fileManager = FileManager.default

    func clean(category: JunkCategory) async throws -> Int64 {
        var freedBytes: Int64 = 0

        switch category.scanMode {
        case .directorySize:
            for path in category.paths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                freedBytes += try deleteContents(of: path)
            }

        case .filesOlderThan, .recursiveFileSearch:
            for item in category.items {
                freedBytes += try deleteItem(at: item.path)
            }
        }

        return freedBytes
    }

    // MARK: - Private

    private func deleteContents(of directory: URL) throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: []
        )

        var freed: Int64 = 0
        for item in contents {
            let size = ScannerService.allocatedSize(of: item)
            try fileManager.removeItem(at: item)
            freed += size
        }
        return freed
    }

    private func deleteItem(at url: URL) throws -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }
        let size = ScannerService.allocatedSize(of: url)
        try fileManager.removeItem(at: url)
        return size
    }
}
