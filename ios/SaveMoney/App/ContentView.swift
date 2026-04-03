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

    // Intercept tab 2 ("+") to show sheet instead of navigating
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == 2 {
                    showAddSheet = true
                } else {
                    selectedTab = newTab
                }
            }
        )
    }

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            TabView(selection: tabSelection) {
                DashboardView()
                    .tag(0)
                    .tabItem { Label("Flow", systemImage: "house.fill") }

                TransactionsView()
                    .tag(1)
                    .tabItem { Label("History", systemImage: "clock.fill") }

                Color.clear
                    .tag(2)
                    .tabItem { Label("Add", systemImage: "plus.circle.fill") }

                AnalyticsView()
                    .tag(3)
                    .tabItem { Label("Insight", systemImage: "chart.bar.fill") }

                SettingsView()
                    .tag(4)
                    .tabItem { Label("Profile", systemImage: "gearshape.fill") }
            }
            .tint(Color.dsPrimary(for: scheme))
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView(isPresented: $showAddSheet)
                .environmentObject(appVM)
        }
    }
}
