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

            // Custom Glass Tab Bar
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

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Flow"),
        ("list.bullet", "History"),
        ("chart.bar.fill", "Insight"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { idx in
                if idx == 2 {
                    // FAB center button
                    Button {
                        showAddTransaction = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(DSColors.accent)
                                .frame(width: 52, height: 52)
                                .shadow(color: DSColors.accent.opacity(0.4), radius: 8, y: 4)
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                Button {
                    selectedTab = idx
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[idx].icon)
                            .font(.system(size: 22))
                            .foregroundStyle(selectedTab == idx ? DSColors.accent : .secondary)
                        Text(tabs[idx].label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(selectedTab == idx ? DSColors.accent : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.bottom, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.xl))
        .padding(.horizontal, DSSpacing.lg)
        .padding(.bottom, 8)
    }
}
