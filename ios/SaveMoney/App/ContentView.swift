import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        MainTabView()
            .task { await app.loadInitData() }
    }
}

// MARK: - Main Tab View (Native Split Tab Bar with Interceptor)
struct MainTabView: View {
    @Environment(AppViewModel.self) private var app
    @State private var selectedTab = 0
    @State private var showAddTransaction = false

    // Tạo Custom Binding để "đánh chặn" thao tác chuyển tab
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == 4 {
                    // Nếu bấm vào Tab "Thêm" (nửa bên phải), bật Sheet lên
                    showAddTransaction = true
                    // KHÔNG gán lại selectedTab để giữ người dùng ở nguyên tab hiện tại
                } else {
                    // Nếu bấm các tab khác, chuyển trang bình thường
                    selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        // Truyền custom binding vào TabView
        TabView(selection: tabSelection) {
            
            Tab(value: 0) {
                DashboardView()
            } label: {
                Label("Flow", systemImage: "house.fill")
                    .symbolEffect(.bounce, value: selectedTab == 0)
            }
            
            Tab(value: 1) {
                TransactionsView()
            } label: {
                Label("History", systemImage: "list.bullet")
                    .symbolEffect(.bounce, value: selectedTab == 1)
            }
            
            Tab(value: 2) {
                AnalyticsView()
            } label: {
                Label("Insight", systemImage: "chart.bar.fill")
                    .symbolEffect(.bounce, value: selectedTab == 2)
            }
            
            Tab(value: 3) {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .symbolEffect(.rotate)
            }
            
            // Dùng role: .search để ép Apple tách Tab này sang nửa bên phải.
            // Biến nó thành nút (+) và truyền value = 4 để bộ đánh chặn ở trên bắt được.
            Tab(value: 4, role: .search) {
                // View rỗng vì code đã chặn ở Binding
            } label: {
                Label("Thêm", systemImage: "plus")
                    .symbolEffect(.bounce, value: showAddTransaction)
            }
        }
        .tabViewStyle(.sidebarAdaptable) // Ép iOS bật chế độ thanh điều hướng nổi (floating)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(transaction: nil) {
                showAddTransaction = false
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
