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
                    // Chỉ sync khi vào app lần đầu nếu có mạng
                    if networkMonitor.isOnline {
                        Task { await appViewModel.syncService.syncPending() }
                    }
                }
                // Loại bỏ .onChange của networkMonitor và scenePhase để tránh tự động sync
        }
        .modelContainer(LocalDataStore.shared.container)
    }
}
