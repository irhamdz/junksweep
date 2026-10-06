import SwiftUI

@main
struct JunkSweepApp: App {
    @State private var store = LibraryStore()

    var body: some Scene {
        WindowGroup {
            // Sweep design on real scan results. HomeView() is the older plain-list UI.
            SweepRootView()
                .environment(store)
        }
    }
}
