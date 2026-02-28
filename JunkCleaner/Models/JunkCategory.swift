import Foundation

enum ScanMode {
    case directorySize
    case filesOlderThan(days: Int)
    case recursiveFileSearch(name: String)
    case recursiveDirectorySearch(name: String)
    case universalBinaries
}

enum PermissionStatus: Equatable {
    case accessible
    case partialAccess(restrictedPaths: [String])
    case denied
}

enum DeletionMode: String, CaseIterable {
    case moveToTrash = "Move to Trash"
    case deletePermanently = "Delete Permanently"
}

struct CleanResult {
    let categoryID: String
    let categoryName: String
    let freedBytes: Int64
    let trashedCount: Int
    let permanentlyDeletedCount: Int
    let errors: [String]
}

struct JunkCategory: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let paths: [URL]
    let scanMode: ScanMode
    var size: Int64 = 0
    var isSelected: Bool = true
    var items: [JunkItem] = []
    var isScanned: Bool = false
    var permissionStatus: PermissionStatus = .accessible

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct JunkItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let modifiedDate: Date?
    let isDirectory: Bool

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
