import SwiftUI

@main
struct SaveMoneyApp: App {
    @State private var appViewModel = AppViewModel()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .environment(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
