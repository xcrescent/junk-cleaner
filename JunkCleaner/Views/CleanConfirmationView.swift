import SwiftUI

struct CleanConfirmationView: View {
    @ObservedObject var viewModel: JunkCleanerViewModel

    private var selectedCategories: [JunkCategory] {
        viewModel.categories.filter(\.isSelected)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("Confirm Cleanup")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(selectedCategories.count) categories selected")
                        .font(.subheadline)
                    Spacer()
                    Text(viewModel.formattedSelectedSize)
                        .font(.subheadline.bold())
                }

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(selectedCategories) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .frame(width: 20)
                                    .foregroundStyle(.secondary)
                                Text(cat.name)
                                Spacer()
                                Text(cat.formattedSize)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

            Picker("Deletion method:", selection: $viewModel.deletionMode) {
                ForEach(DeletionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.showCleanConfirmation = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Clean") {
                    viewModel.confirmClean()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
