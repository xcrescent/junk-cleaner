import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: JunkCleanerViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            // Progress bar during scan/clean
            progressBar

            if viewModel.categories.isEmpty {
                emptyState
            } else {
                categoryList
            }

            Divider()
            footerSection
        }
        .frame(minWidth: 600, minHeight: 450)
        .sheet(isPresented: $viewModel.showCleanConfirmation) {
            CleanConfirmationView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "trash.square")
                .font(.title)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text("Junk Cleaner")
                    .font(.title2.bold())
                Text("Find and remove unnecessary files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if viewModel.hasScanned {
                VStack(alignment: .trailing) {
                    Text(viewModel.formattedTotalSize)
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                        .animation(.spring, value: viewModel.totalSize)
                    Text("total junk found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBar: some View {
        switch viewModel.state {
        case .scanning(let progress):
            ProgressView(value: progress)
                .tint(.orange)
                .animation(.easeInOut, value: progress)
        case .cleaning(let progress):
            ProgressView(value: progress)
                .tint(.red)
                .animation(.easeInOut, value: progress)
        default:
            EmptyView()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Click Scan to find junk files")
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category List

    private var categoryList: some View {
        List {
            ForEach(viewModel.categories) { category in
                CategoryRowView(
                    category: category,
                    isExpanded: viewModel.expandedCategoryID == category.id,
                    onToggleSelected: { viewModel.toggleCategory(category.id) },
                    onToggleExpanded: { viewModel.toggleExpanded(category.id) },
                    onRevealInFinder: { url in viewModel.revealInFinder(url) }
                )
                .opacity(category.isScanned ? 1.0 : 0.6)
                .animation(.easeIn(duration: 0.3), value: category.isScanned)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if viewModel.hasScanned {
                Button("Select All") { viewModel.selectAll() }
                    .buttonStyle(.plain)
                Button("Deselect All") { viewModel.deselectAll() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                if !viewModel.categoriesWithPermissionIssues.isEmpty {
                    Button {
                        viewModel.openFullDiskAccessSettings()
                    } label: {
                        Label("Grant Full Disk Access", systemImage: "lock.shield")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.orange)
                }

                Spacer()

                Text("Selected: \(viewModel.formattedSelectedSize)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Spacer()
            }

            statusMessage

            if viewModel.isWorking {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 4)
            }

            Button(viewModel.hasScanned ? "Scan Again" : "Scan") {
                viewModel.startScan()
            }
            .disabled(viewModel.isWorking)

            if viewModel.hasScanned {
                Button("Clean Selected") {
                    viewModel.requestClean()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .disabled(viewModel.isWorking || viewModel.selectedSize == 0)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.state {
        case .scanning(let progress):
            Text("Scanning... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .cleaning(let progress):
            Text("Cleaning... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .cleaned(let freedBytes, let trashedCount, let permanentlyDeletedCount):
            VStack(alignment: .trailing, spacing: 2) {
                Text("Freed \(ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file))")
                    .font(.caption)
                    .foregroundStyle(.green)
                if trashedCount > 0 {
                    Text("\(trashedCount) items moved to Trash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if permanentlyDeletedCount > 0 {
                    Text("\(permanentlyDeletedCount) items permanently deleted")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        case .error(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
                .help(message)
        default:
            EmptyView()
        }
    }
}
