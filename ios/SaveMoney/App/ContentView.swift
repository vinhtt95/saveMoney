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

            // Custom Glass Tab Bar với hiệu ứng Liquid nảy mềm mại
            DSTabBarView(
                selectedTab: $selectedTab,
                showAddTransaction: $showAddTransaction
            )
            // Ép thanh Nav Bar bỏ qua khoảng trống Safe Area của thanh Home
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
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
            // --- Left pill: 4 nav tabs ---
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { idx in
                    let isSelected = selectedTab == idx
                    
                    Button {
                        // Hiệu ứng giật nảy sang tab mới (giống video thạch)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                            selectedTab = idx
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tabs[idx].icon)
                                .font(.system(size: 20))
                                // Icon hơi lún xuống khi nhấn
                                .scaleEffect(isPressing && pressingIdx == idx ? 0.85 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)
                            
                            Text(tabs[idx].label)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(isSelected ? DSColors.accent : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LiquidButtonStyle(idx: idx, isPressing: $isPressing, pressingIdx: $pressingIdx))
                    .background {
                        if isSelected {
                            // Giọt nước (Gooey Layer) mờ ảo không có viền sắc nét
                            Capsule()
                                .fill(.ultraThinMaterial)
                                // Lớp glow phát sáng phía sau thay vì viền cứng
                                .background(
                                    Capsule()
                                        .fill(DSColors.accent.opacity(0.25))
                                        .blur(radius: 10)
                                )
                                // Khi nhấn giữ, giọt nước phình to ra
                                .scaleEffect(isPressing && pressingIdx == idx ? 1.15 : 1.0)
                                .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                                .padding(4)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            // Lớp vỏ kính bên ngoài cho toàn bộ cụm Tab bên trái
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                    .overlay(Capsule().stroke(Color(.separator).opacity(0.2), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }

            // --- Right pill: Add button ---
            Button {
                showAddTransaction = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DSColors.accent)
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(PlainButtonStyle())
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16) 
        // Đặt khoảng cách tĩnh chính xác là 10px so với mép dưới màn hình
        .padding(.bottom, 10) 
    }
}

// MARK: - Liquid Button Style
struct LiquidButtonStyle: ButtonStyle {
    let idx: Int
    @Binding var isPressing: Bool
    @Binding var pressingIdx: Int?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                if newValue {
                    pressingIdx = idx
                    // Tốc độ phình to ra khi chạm vào
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7)) {
                        isPressing = true
                    }
                } else {
                    // Tốc độ thu nhỏ lại khi nhả ra
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPressing = false
                        pressingIdx = nil
                    }
                }
            }
    }
}