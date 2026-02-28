import Foundation
import AppKit

enum AppState: Equatable {
    case idle
    case scanning(progress: Double)
    case scanned
    case cleaning(progress: Double)
    case cleaned(freedBytes: Int64, trashedCount: Int, permanentlyDeletedCount: Int)
    case error(message: String)
}

@MainActor
final class JunkCleanerViewModel: ObservableObject {
    @Published var categories: [JunkCategory] = []
    @Published var state: AppState = .idle
    @Published var expandedCategoryID: String? = nil
    @Published var showCleanConfirmation: Bool = false
    @Published var deletionMode: DeletionMode = .moveToTrash

    private let scanner = ScannerService()
    private let cleaner = CleanerService()
    private var scanTask: Task<Void, Never>?

    var totalSize: Int64 {
        categories.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        categories.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    var hasScanned: Bool {
        switch state {
        case .scanned, .cleaned: return true
        default: return false
        }
    }

    var isWorking: Bool {
        switch state {
        case .scanning, .cleaning: return true
        default: return false
        }
    }

    var categoriesWithPermissionIssues: [JunkCategory] {
        categories.filter {
            if case .accessible = $0.permissionStatus { return false }
            return true
        }
    }

    // MARK: - Actions

    func startScan() {
        scanTask?.cancel()
        categories = scanner.buildCategories()
        state = .scanning(progress: 0)

        scanTask = Task {
            let total = Double(categories.count)

            for (index, category) in categories.enumerated() {
                guard !Task.isCancelled else { return }

                let scanned = await scanner.scan(category: category)

                if let catIndex = categories.firstIndex(where: { $0.id == scanned.id }) {
                    categories[catIndex] = scanned
                }

                state = .scanning(progress: Double(index + 1) / total)
            }

            state = .scanned
        }
    }

    func requestClean() {
        guard hasScanned else { return }
        let selectedCategories = categories.filter(\.isSelected)
        guard !selectedCategories.isEmpty else { return }
        showCleanConfirmation = true
    }

    func confirmClean() {
        showCleanConfirmation = false
        guard hasScanned else { return }

        let selectedCategories = categories.filter(\.isSelected)
        guard !selectedCategories.isEmpty else { return }

        state = .cleaning(progress: 0)

        Task {
            var totalFreed: Int64 = 0
            var totalTrashed = 0
            var totalPermanentlyDeleted = 0
            let total = Double(selectedCategories.count)
            var allErrors: [String] = []

            for (index, category) in selectedCategories.enumerated() {
                // Force permanent delete for Trash category (can't trash items already in Trash)
                let mode: DeletionMode = category.id == "trash" ? .deletePermanently : deletionMode

                let result = await cleaner.clean(category: category, mode: mode)
                totalFreed += result.freedBytes
                totalTrashed += result.trashedCount
                totalPermanentlyDeleted += result.permanentlyDeletedCount
                allErrors.append(contentsOf: result.errors)

                if let catIndex = categories.firstIndex(where: { $0.id == category.id }) {
                    categories[catIndex].size = 0
                    categories[catIndex].items = []
                    categories[catIndex].isScanned = false
                }

                state = .cleaning(progress: Double(index + 1) / total)
            }

            if allErrors.isEmpty {
                state = .cleaned(freedBytes: totalFreed, trashedCount: totalTrashed, permanentlyDeletedCount: totalPermanentlyDeleted)
            } else {
                state = .error(message: allErrors.joined(separator: "\n"))
            }
        }
    }

    func toggleCategory(_ id: String) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for index in categories.indices {
            categories[index].isSelected = true
        }
    }

    func deselectAll() {
        for index in categories.indices {
            categories[index].isSelected = false
        }
    }

    func toggleExpanded(_ id: String) {
        expandedCategoryID = expandedCategoryID == id ? nil : id
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
