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
    @State private var visitedTabs: Set<Int> = [0]
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            DSMeshBackground().ignoresSafeArea()

            // Tab content — ZStack with crossfade; views stay alive after first visit (no re-init)
            ZStack {
                if visitedTabs.contains(0) {
                    DashboardView()
                        .opacity(selectedTab == 0 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 0)
                }
                if visitedTabs.contains(1) {
                    TransactionsView()
                        .opacity(selectedTab == 1 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 1)
                }
                if visitedTabs.contains(3) {
                    AnalyticsView()
                        .opacity(selectedTab == 3 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 3)
                }
                if visitedTabs.contains(4) {
                    SettingsView()
                        .opacity(selectedTab == 4 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 4)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
            .onChange(of: selectedTab) { _, tab in visitedTabs.insert(tab) }
            // Reserve space at bottom for tab bar
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarHeight)
            }
            .ignoresSafeArea(edges: .top)

            // Tab bar floats on top, fully blocks touches in its area
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                DSTabBar(selectedTab: $selectedTab, onAddTap: { showAddSheet = true })
                    .padding(.bottom, max(safeAreaBottom - 4, 0))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView(isPresented: $showAddSheet)
                .environmentObject(appVM)
        }
        // Force the entire ZStack (including tab bar layer) to honour the chosen scheme
        .preferredColorScheme(themeManager.colorScheme)
    }

    private var tabBarHeight: CGFloat { 80 }

    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom) ?? 0
    }
}
