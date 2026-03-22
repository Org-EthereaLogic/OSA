import SwiftUI

@main
struct OSAApp: App {
    private let sharedModelContainer = AppModelContainer.makeShared()

    var body: some Scene {
        WindowGroup {
            AppTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
