import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Group {
            if appVM.isLoading {
                loadingView
            } else if let error = appVM.loadError {
                errorView(error)
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
                        .stroke(Color.dsPrimaryDark.opacity(0.2), lineWidth: 3)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(colors: [Color.dsPrimaryDark, Color.dsSecondaryDark],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    ProgressView()
                        .tint(Color.dsPrimaryDark)
                }
                Text("Đang tải dữ liệu...")
                    .font(.dsBody(15))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            }
        }
    }

    private func errorView(_ error: String) -> some View {
        ZStack {
            DSMeshBackground()
            GlassCard(radius: DSRadius.xl, padding: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "#fbbf24"))
                    Text("Không thể kết nối")
                        .font(.dsDisplay(20))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    Text(error)
                        .font(.dsBody(13))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .multilineTextAlignment(.center)
                    GlassPillButton(label: "Thử lại") {
                        Task { await appVM.loadInitData() }
                    }
                }
            }
            .padding(.horizontal, 40)
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
