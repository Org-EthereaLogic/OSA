import SwiftData
import SwiftUI

@main
struct OSAApp: App {
    private let sharedModelContainer: ModelContainer
    private let dependencies: AppDependencies
    private let isUITesting: Bool
    private let userDefaults: UserDefaults

    init() {
        let runtime = AppRuntimeConfiguration.current()
        runtime.prepareForLaunch()
        AppClock.install(runtime.nowProvider)

        self.isUITesting = runtime.isUITesting
        self.userDefaults = runtime.userDefaults

        let container = AppModelContainer.makeShared(runtime: runtime)
        self.sharedModelContainer = container
        let deps = AppDependencies.live(modelContainer: container, runtime: runtime)
        self.dependencies = deps
        SharedRuntime.install(deps)
    }

    var body: some Scene {
        WindowGroup {
            OSARootView(
                dependencies: dependencies,
                isUITesting: isUITesting,
                userDefaults: userDefaults
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
