import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Group {
            if app.isLoading {
                LoadingView()
            } else {
                MainTabView()
            }
        }
        .task { await app.loadInitData() }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(AppViewModel.self) private var app
    @State private var selectedTab = 0
    @State private var showAddTransaction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                TransactionsView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)

                AnalyticsView()
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)

                SettingsView()
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)
            }

            // Custom Glass Tab Bar với hiệu ứng Liquid
            DSTabBarView(
                selectedTab: $selectedTab,
                showAddTransaction: $showAddTransaction
            )
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(transaction: nil) {
                showAddTransaction = false
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - DSTabBar View
struct DSTabBarView: View {
    @Binding var selectedTab: Int
    @Binding var showAddTransaction: Bool
    @Namespace private var tabNamespace
    
    // State để bắt hiệu ứng nhấn giữ phình to giọt nước
    @State private var isPressing: Bool = false
    @State private var pressingIdx: Int? = nil

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Flow"),
        ("list.bullet", "History"),
        ("chart.bar.fill", "Insight"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 12) {
            // --- Left pill: 4 nav tabs (Hiệu ứng Apple Music) ---
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { idx in
                    let isSelected = selectedTab == idx
                    
                    Button {
                        // Hiệu ứng di chuyển "quánh" như chất lỏng
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
                            selectedTab = idx
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tabs[idx].icon)
                                .font(.system(size: 20))
                                // Icon hơi thu nhỏ nhẹ khi đang nhấn giữ
                                .scaleEffect(isPressing && pressingIdx == idx ? 0.9 : 1.0)
                            Text(tabs[idx].label)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(isSelected ? DSColors.accent : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LiquidButtonStyle(idx: idx, isPressing: $isPressing, pressingIdx: $pressingIdx))
                    .background {
                        if isSelected {
                            // Đây là "Giọt nước" (Gooey Layer)
                            Capsule()
                                .fill(.thinMaterial)
                                // Khi nhấn giữ, giọt nước phình to ra như ảnh mày gửi
                                .scaleEffect(isPressing && pressingIdx == idx ? 1.25 : 1.0)
                                .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                                .padding(4)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .glassEffect(.regular, in: .capsule)

            // --- Right pill: Add button (Giữ nguyên layout của mày) ---
            Button {
                showAddTransaction = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DSColors.accent)
                    .frame(width: 60, height: 60)
                    .glassEffect(.regular, in: .circle)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.bottom, 0) // Độ cao hợp lý so với cạnh dưới iPhone
    }
}

// MARK: - Liquid Button Style
// Helper để xử lý trạng thái nhấn giữ (Long press animation)
struct LiquidButtonStyle: ButtonStyle {
    let idx: Int
    @Binding var isPressing: Bool
    @Binding var pressingIdx: Int?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                if newValue {
                    pressingIdx = idx
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.5)) {
                        isPressing = true
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPressing = false
                        pressingIdx = nil
                    }
                }
            }
    }
}