import SwiftUI
import SwiftData

@main
struct SaveMoneyApp: App {
    @State private var appViewModel = AppViewModel()
    @State private var themeManager = ThemeManager()
    @State private var networkMonitor = NetworkMonitor()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .environment(themeManager)
                .environment(networkMonitor)
                .preferredColorScheme(themeManager.colorScheme)
                .tint(DSColors.accent)
                .onAppear {
                    appViewModel.networkMonitor = networkMonitor
                }
                .onChange(of: networkMonitor.isOnline) { oldState, newState in
                    appViewModel.handleNetworkChange(from: oldState, to: newState)
                }
        }
        .modelContainer(LocalDataStore.shared.container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                appViewModel.handleAppActive()
            }
        }
    }
}
