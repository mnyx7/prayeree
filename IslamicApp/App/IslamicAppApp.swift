import SwiftUI

@main
struct IslamicAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment: AppEnvironment
    @State private var appStore: AppStore

    init() {
        let environment = AppEnvironment.live()
        _environment = State(initialValue: environment)
        _appStore = State(initialValue: AppStore(environment: environment))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(appStore: appStore, environment: environment)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { appStore.send(.appLaunched) }
                }
                .task {
                    appStore.send(.appLaunched)
                }
        }
    }
}
