import SwiftUI

struct CategoryDetailView: View {
    let items: [JunkItem]
    let onRevealInFinder: (URL) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(items) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 14)

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

                        Button {
                            onRevealInFinder(item.path)
                        } label: {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                    .padding(.vertical, 1)
                }
            }
        }
        .frame(maxHeight: 300)
        .padding(.bottom, 8)
    }
}
