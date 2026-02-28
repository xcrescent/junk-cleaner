import Foundation

enum ScanMode {
    case directorySize
    case filesOlderThan(days: Int)
    case recursiveFileSearch(name: String)
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

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
