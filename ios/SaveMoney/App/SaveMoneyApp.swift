import SwiftUI
import SwiftData

@main
struct SaveMoneyApp: App {
    @State private var appViewModel = AppViewModel()
    @State private var themeManager = ThemeManager()
    @State private var networkMonitor = NetworkMonitor()

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
                .onChange(of: networkMonitor.isOnline) { oldValue, newValue in
                    appViewModel.handleNetworkChange(from: oldValue, to: newValue)
                }
        }
        .modelContainer(LocalDataStore.shared.container)
    }
}
