import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(ThemeManager.self) private var theme
    @State private var settingsVM: SettingsViewModel?

    private var vm: SettingsViewModel {
        settingsVM ?? SettingsViewModel(app: app)
    }

    var body: some View {
        NavigationStack {
            List {
                // Connection Status
                Section {
                    HStack(spacing: DSSpacing.sm) {
                        Circle()
                            .fill(app.connectionState.color)
                            .frame(width: 10, height: 10)
                        Text(app.connectionState.label)
                            .font(.subheadline)
                        Spacer()
                        if app.connectionState == .loading {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                }

                // Base URL
                Section("Địa chỉ máy chủ") {
                    HStack {
                        TextField("http://localhost:3001", text: Binding(
                            get: { vm.baseURL },
                            set: { vm.baseURL = $0 }
                        ))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button("Lưu") {
                            Task { await vm.saveBaseURL() }
                        }
                        .foregroundStyle(DSColors.accent)
                        .disabled(vm.isSubmitting)
                    }

                    if vm.saveSuccess {
                        Label("Đã lưu", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                // Theme
                Section("Giao diện") {
                    Picker("Chủ đề", selection: Binding(
                        get: { theme.theme },
                        set: { theme.theme = $0 }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Default Settings
                Section("Mặc định") {
                    Picker("Loại giao dịch", selection: Binding(
                        get: { app.defaultTransactionType },
                        set: { newValue in Task { await vm.updateDefaultType(newValue) } }
                    )) {
                        Text("Chi tiêu").tag(TransactionType.expense)
                        Text("Thu nhập").tag(TransactionType.income)
                    }

                    Picker("Tài khoản", selection: Binding(
                        get: { app.defaultAccountId ?? "" },
                        set: { newValue in Task { await vm.updateDefaultAccount(newValue) } }
                    )) {
                        Text("— Không chọn —").tag("")
                        ForEach(app.accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                }

                // Navigation
                Section("Quản lý") {
                    NavigationLink("Ngân sách") { BudgetView() }
                    NavigationLink("Tài khoản") { AccountsView() }
                    NavigationLink("Danh mục") { CategoriesView() }
                    NavigationLink("Giá vàng") { GoldView() }
                    NavigationLink("Tài sản ròng") { WealthView() }
                }

                // App Info
                Section {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("SaveMoney")
                        Spacer()
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(DSColors.income)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if settingsVM == nil {
                settingsVM = SettingsViewModel(app: app)
            }
        }
    }
}
