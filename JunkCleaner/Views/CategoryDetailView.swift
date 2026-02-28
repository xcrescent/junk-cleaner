import SwiftUI

struct CategoryDetailView: View {
    let items: [JunkItem]

    private var displayItems: [JunkItem] {
        Array(items.prefix(20))
    }

    private var hasMore: Bool {
        items.count > 20
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(displayItems) { item in
                HStack {
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    if let date = item.modifiedDate {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(item.formattedSize)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 1)
            }

            if hasMore {
                Text("... and \(items.count - 20) more items")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
        .padding(.bottom, 8)
    }
}
