import Foundation

enum AppState: Equatable {
    case idle
    case scanning(progress: Double)
    case scanned
    case cleaning(progress: Double)
    case cleaned(freedBytes: Int64)
    case error(message: String)
}

@MainActor
final class JunkCleanerViewModel: ObservableObject {
    @Published var categories: [JunkCategory] = []
    @Published var state: AppState = .idle
    @Published var expandedCategoryID: String? = nil

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

    func startClean() {
        guard hasScanned else { return }

        let selectedCategories = categories.filter(\.isSelected)
        guard !selectedCategories.isEmpty else { return }

        state = .cleaning(progress: 0)

        Task {
            var totalFreed: Int64 = 0
            let total = Double(selectedCategories.count)
            var errors: [String] = []

            for (index, category) in selectedCategories.enumerated() {
                do {
                    let freed = try await cleaner.clean(category: category)
                    totalFreed += freed

                    if let catIndex = categories.firstIndex(where: { $0.id == category.id }) {
                        categories[catIndex].size = 0
                        categories[catIndex].items = []
                        categories[catIndex].isScanned = false
                    }
                } catch {
                    errors.append("\(category.name): \(error.localizedDescription)")
                }

                state = .cleaning(progress: Double(index + 1) / total)
            }

            if errors.isEmpty {
                state = .cleaned(freedBytes: totalFreed)
            } else {
                state = .error(message: errors.joined(separator: "\n"))
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
}
