import SwiftUI

struct CategoryRowView: View {
    let category: JunkCategory
    let isExpanded: Bool
    let onToggleSelected: () -> Void
    let onToggleExpanded: () -> Void
    let onRevealInFinder: (URL) -> Void

    @State private var isHovered = false

    private var sizeColor: Color {
        if category.size < 100_000_000 { return .green }
        if category.size < 1_000_000_000 { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Toggle("", isOn: Binding(
                    get: { category.isSelected },
                    set: { _ in onToggleSelected() }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()

                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body.weight(.medium))
                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if case .partialAccess(let restricted) = category.permissionStatus {
                        Text("\(restricted.count) path(s) restricted")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                if category.isScanned {
                    Text(category.formattedSize)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(category.size > 0 ? sizeColor : .secondary)

                    if case .partialAccess = category.permissionStatus {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .help("Some items could not be accessed. Grant Full Disk Access for a complete scan.")
                    } else if case .denied = category.permissionStatus {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .help("Permission denied. Grant Full Disk Access to scan this category.")
                    }
                } else {
                    ProgressView()
                        .controlSize(.small)
                }

                if category.isScanned && !category.items.isEmpty {
                    Button(action: onToggleExpanded) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())

            if isExpanded {
                CategoryDetailView(items: category.items, onRevealInFinder: onRevealInFinder)
                    .padding(.leading, 56)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
}
