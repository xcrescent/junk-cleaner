import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: JunkCleanerViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if viewModel.categories.isEmpty {
                emptyState
            } else {
                categoryList
            }

            Divider()
            footerSection
        }
        .frame(minWidth: 600, minHeight: 450)
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
                    Text("total junk found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
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
                    onToggleExpanded: { viewModel.toggleExpanded(category.id) }
                )
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
                    viewModel.startClean()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
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
        case .cleaned(let freedBytes):
            Text("Freed \(ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file))")
                .font(.caption)
                .foregroundStyle(.green)
        case .error(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(1)
                .help(message)
        default:
            EmptyView()
        }
    }
}
