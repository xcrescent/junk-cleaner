import SwiftUI

@main
struct JunkCleanerApp: App {
    @StateObject private var viewModel = JunkCleanerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .defaultSize(width: 700, height: 550)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
