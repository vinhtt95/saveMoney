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
                    // Sync pending ops if already online at launch
                    if networkMonitor.isOnline {
                        Task { await appViewModel.syncService.syncPending() }
                    }
                }
                .onChange(of: networkMonitor.isOnline) { oldValue, newValue in
                    appViewModel.handleNetworkChange(from: oldValue, to: newValue)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && networkMonitor.isOnline {
                        Task { await appViewModel.syncService.syncPending() }
                    }
                }
        }
        .modelContainer(LocalDataStore.shared.container)
    }
}
