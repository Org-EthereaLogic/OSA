import SwiftData
import SwiftUI

@main
struct OSAApp: App {
    private let sharedModelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let container = AppModelContainer.makeShared()
        self.sharedModelContainer = container
        self.dependencies = AppDependencies.live(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environment(\.handbookRepository, dependencies.handbookRepository)
                .environment(\.quickCardRepository, dependencies.quickCardRepository)
        }
        .modelContainer(sharedModelContainer)
    }
}
