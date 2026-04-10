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
            
            Tab("Flow", systemImage: "house.fill", value: 0) {
                DashboardView()
            }
            
            Tab("History", systemImage: "list.bullet", value: 1) {
                TransactionsView()
            }
            
            Tab("Insight", systemImage: "chart.bar.fill", value: 2) {
                AnalyticsView()
            }
            
            Tab("Settings", systemImage: "gearshape.fill", value: 3) {
                SettingsView()
            }
            
            // Dùng role: .search để ép Apple tách Tab này sang nửa bên phải.
            // Biến nó thành nút (+) và truyền value = 4 để bộ đánh chặn ở trên bắt được.
            Tab("Thêm", systemImage: "plus", value: 4, role: .search) {
                Color.clear // View rỗng vì code đã chặn, không bao giờ load vào màn hình này
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
