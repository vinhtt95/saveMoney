import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        Group {
            if appVM.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Đang tải dữ liệu...")
                        .foregroundColor(.secondary)
                }
            } else if let error = appVM.loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Không thể kết nối")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Thử lại") {
                        Task { await appVM.loadInitData() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                MainTabView()
            }
        }
        .task {
            await appVM.loadInitData()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Tổng quan", systemImage: "house.fill") }

            TransactionsView()
                .tabItem { Label("Giao dịch", systemImage: "list.bullet.rectangle") }

            AnalyticsView()
                .tabItem { Label("Thống kê", systemImage: "chart.bar.fill") }

            BudgetView()
                .tabItem { Label("Ngân sách", systemImage: "chart.pie.fill") }

            GoldView()
                .tabItem { Label("Vàng", systemImage: "circle.fill") }

            WealthView()
                .tabItem { Label("Tài sản", systemImage: "banknote.fill") }

            AccountsView()
                .tabItem { Label("Tài khoản", systemImage: "creditcard.fill") }

            CategoriesView()
                .tabItem { Label("Danh mục", systemImage: "tag.fill") }

            SettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
    }
}
