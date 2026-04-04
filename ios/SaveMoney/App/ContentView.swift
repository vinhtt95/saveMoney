import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Group {
            if appVM.isLoading {
                loadingView
            } else {
                MainTabView()
                    .environmentObject(themeManager)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .task {
            await appVM.loadInitData()
        }
    }

    private var loadingView: some View {
        ZStack {
            DSMeshBackground()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.dsBrandAccent.opacity(0.2), lineWidth: 3)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(colors: [Color.dsBrandAccent, Color(UIColor.systemTeal)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    ProgressView()
                        .tint(Color.dsBrandAccent)
                }
                Text("Đang tải dữ liệu...")
                    .font(.dsBody(15))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            }
        }
    }

}

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var scheme
    @State private var selectedTab = 0
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                TransactionsView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)

                AnalyticsView()
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)

                SettingsView()
                    .tag(4)
                    .toolbar(.hidden, for: .tabBar)
            }
            .tint(Color.dsPrimary(for: scheme))
            .safeAreaInset(edge: .bottom) {
                DSTabBar(selectedTab: $selectedTab, onAddTap: { showAddSheet = true })
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView(isPresented: $showAddSheet)
                .environmentObject(appVM)
        }
    }
}
