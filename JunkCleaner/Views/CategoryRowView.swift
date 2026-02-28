import SwiftUI

struct CategoryRowView: View {
    let category: JunkCategory
    let isExpanded: Bool
    let onToggleSelected: () -> Void
    let onToggleExpanded: () -> Void

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
                }

                Spacer()

                if category.isScanned {
                    Text(category.formattedSize)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(category.size > 0 ? .primary : .secondary)
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
                CategoryDetailView(items: category.items)
                    .padding(.leading, 56)
            }
        }
    }
}
