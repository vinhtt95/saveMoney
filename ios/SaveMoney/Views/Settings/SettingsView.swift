import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var vm = SettingsViewModel()
    @Environment(\.colorScheme) var scheme

    private var defaultType: Binding<String> {
        Binding(
            get: { appVM.settings["default_transaction_type"] ?? "expense" },
            set: { appVM.settings["default_transaction_type"] = $0 }
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile hero
                        profileHero
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        // Theme toggle
                        themeSection
                            .padding(.horizontal, 20)

                        // Management links
                        managementSection
                            .padding(.horizontal, 20)

                        // Backend settings
                        backendSection
                            .padding(.horizontal, 20)

                        // Default settings
                        defaultsSection
                            .padding(.horizontal, 20)

                        // Status messages
                        if vm.saveSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dsIncome)
                                Text("Đã lưu thành công")
                                    .font(.dsBody(14))
                                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                            }
                            .padding(.horizontal, 20)
                        }
                        if let err = vm.saveError {
                            Text(err)
                                .font(.dsBody(12))
                                .foregroundStyle(Color.dsExpense)
                                .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Profile Hero

    private var profileHero: some View {
        GlassCard(radius: DSRadius.xl, padding: 20) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.dsCTAGradient(scheme: scheme))
                        .frame(width: 56, height: 56)
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("SaveMoney")
                        .font(.dsDisplay(20))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    Text("Phiên bản 1.0.0")
                        .font(.dsBody(13))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                }
                Spacer()
            }
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DSSectionHeader(title: "Giao diện")
            GlassCard(radius: DSRadius.lg, padding: 16) {
                VStack(spacing: 14) {
                    HStack {
                        GradientCircleIcon(systemName: "circle.lefthalf.filled",
                                           colors: [Color.dsBrandAccent, Color(UIColor.systemTeal)],
                                           size: 34)
                        Text("Chế độ hiển thị")
                            .font(.dsBody(15))
                            .foregroundStyle(Color.dsOnSurface(for: scheme))
                        Spacer()
                    }
                    Picker("Giao diện", selection: $themeManager.preference) {
                        Text("Hệ thống").tag("system")
                        Text("Sáng").tag("light")
                        Text("Tối").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - Management Section

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DSSectionHeader(title: "Quản lý")
            GlassCard(radius: DSRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    navRow(icon: "chart.pie.fill",
                           colors: [Color(hex: "#c799ff"), Color(hex: "#4af8e3")],
                           title: "Ngân sách",
                           destination: BudgetView())
                    Divider().opacity(0.15).padding(.horizontal, 16)
                    navRow(icon: "creditcard.fill",
                           colors: [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")],
                           title: "Tài khoản",
                           destination: AccountsView())
                    Divider().opacity(0.15).padding(.horizontal, 16)
                    navRow(icon: "tag.fill",
                           colors: [Color(hex: "#fbbf24"), Color(hex: "#f59e0b")],
                           title: "Danh mục",
                           destination: CategoriesView())
                    Divider().opacity(0.15).padding(.horizontal, 16)
                    navRow(icon: "circle.fill",
                           colors: [Color(hex: "#fbbf24"), Color(hex: "#f97316")],
                           title: "Vàng",
                           destination: GoldView())
                    Divider().opacity(0.15).padding(.horizontal, 16)
                    navRow(icon: "banknote.fill",
                           colors: [Color(hex: "#4af8e3"), Color(hex: "#059669")],
                           title: "Tài sản",
                           destination: WealthView())
                }
            }
        }
    }

    private func navRow<D: View>(icon: String, colors: [Color], title: String, destination: D) -> some View {
        NavigationLink(destination: destination.environmentObject(appVM)) {
            HStack(spacing: 12) {
                GradientCircleIcon(systemName: icon, colors: colors, size: 34)
                Text(title)
                    .font(.dsBody(15))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Backend Section

    private var backendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DSSectionHeader(title: "Kết nối Backend")
            GlassCard(radius: DSRadius.lg, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    GlassFormField(label: "Server URL", text: $vm.baseURL,
                                   keyboardType: .URL,
                                   placeholder: "http://localhost:3001",
                                   disableAutocorrect: true,
                                   autocapitalization: .never)

                    Text("Dùng IP LAN (vd: http://192.168.1.x:3001) khi chạy trên thiết bị thật.")
                        .font(.dsBody(11))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))

                    GlassPillButton(label: "Lưu URL") {
                        vm.saveBaseURL()
                        Task { await appVM.loadInitData() }
                    }
                    .disabled(vm.baseURL.isEmpty)
                }
            }
        }
    }

    // MARK: - Defaults Section

    private var defaultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DSSectionHeader(title: "Mặc định giao dịch")
            GlassCard(radius: DSRadius.lg, padding: 16) {
                VStack(spacing: 14) {
                    HStack {
                        Text("Loại mặc định")
                            .font(.dsBody(14))
                            .foregroundStyle(Color.dsOnSurface(for: scheme))
                        Spacer()
                        Picker("Loại mặc định", selection: defaultType) {
                            Text("Chi tiêu").tag("expense")
                            Text("Thu nhập").tag("income")
                        }
                        .pickerStyle(.menu)
                        .tint(Color.dsPrimary(for: scheme))
                    }

                    HStack {
                        Text("Tài khoản mặc định")
                            .font(.dsBody(14))
                            .foregroundStyle(Color.dsOnSurface(for: scheme))
                        Spacer()
                        Picker("Tài khoản mặc định", selection: Binding(
                            get: { appVM.settings["default_account_id"] ?? "" },
                            set: { appVM.settings["default_account_id"] = $0 }
                        )) {
                            Text("Không chọn").tag("")
                            ForEach(appVM.accounts) { acc in
                                Text(acc.name).tag(acc.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.dsPrimary(for: scheme))
                    }

                    GlassPillButton(label: vm.isSaving ? "Đang lưu..." : "Lưu cài đặt") {
                        Task { await vm.saveDefaults(settings: appVM.settings, appVM: appVM) }
                    }
                    .disabled(vm.isSaving)
                }
            }
        }
    }
}
