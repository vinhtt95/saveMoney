import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(ThemeManager.self) private var theme
    @State private var settingsVM: SettingsViewModel?

    private var vm: SettingsViewModel {
        settingsVM ?? SettingsViewModel(app: app)
    }

    var body: some View {
        NavigationStack{
            ZStack {
                LiquidBackgroundView()
                
                List {
                    // 1. Quản lý
                    Section("Quản lý") {
                        NavigationLink(destination: BudgetView()) {
                            Label { Text("Ngân sách").lineLimit(1) } icon: { Image(systemName: "chart.pie.fill") }
                        }
                        NavigationLink(destination: AccountsView()) {
                            Label { Text("Tài khoản").lineLimit(1) } icon: { Image(systemName: "creditcard.fill") }
                        }
                        NavigationLink(destination: CategoriesView()) {
                            Label { Text("Danh mục").lineLimit(1) } icon: { Image(systemName: "tag.fill") }
                        }
                        NavigationLink(destination: GoldView()) {
                            Label { Text("Giá vàng").lineLimit(1) } icon: { Image(systemName: "bitcoinsign.circle.fill") }
                        }
                        NavigationLink(destination: WealthView()) {
                            Label { Text("Tài sản ròng").lineLimit(1) } icon: { Image(systemName: "briefcase.fill") }
                        }
                    }
                    
                    // 2. General
                    Section("General") {
                        // Giao diện (giữ lại vì thuộc về App UI)
                        HStack {
                            Label("Giao diện", systemImage: "paintbrush.fill")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { theme.theme },
                                set: { theme.theme = $0 }
                            )) {
                                ForEach(AppTheme.allCases, id: \.self) { t in
                                    Text(t.label).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // MỤC CHUNG MỚI: Cài đặt mặc định
                        NavigationLink(destination: DefaultSettingsView(vm: vm)) {
                            Label("Cài đặt mặc định", systemImage: "gearshape.2.fill")
                        }
                        
                        // Địa chỉ máy chủ
                        NavigationLink(destination: serverSettingsView) {
                            Label("Địa chỉ máy chủ", systemImage: "server.rack")
                        }
                    }
                    
                    // 3. Info
                    Section {
                        HStack {
                            Label { Text("Phiên bản").lineLimit(1) } icon: { Image(systemName: "info.circle") }
                            Spacer()
                            Text("1.0.0").foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                if settingsVM == nil { settingsVM = SettingsViewModel(app: app) }
            }
        }
    }

    private var serverSettingsView: some View {
        List {
            Section("Kết nối") {
                // 1. Kiểm tra Internet của thiết bị
                HStack {
                    Text("Internet")
                    Spacer()
                    Text(app.isOnline ? "Đã kết nối" : "Mất kết nối")
                        .foregroundStyle(app.isOnline ? .green : .secondary)
                }
                
                // 2. Kiểm tra trạng thái thực tế với Server
                HStack {
                    Text("Máy chủ")
                    Spacer()
                    Group {
                        switch app.connectionState {
                        case .connected:
                            Text("Sẵn sàng").foregroundStyle(.green)
                        case .loading:
                            Text("Đang kiểm tra...").foregroundStyle(.orange)
                        case .disconnected:
                            Text("Không phản hồi").foregroundStyle(.red)
                        }
                    }
                }
                
                Button(action: { Task { await vm.manualReconnect() } }) {
                    if vm.isSubmitting {
                        ProgressView().padding(.trailing, 5)
                    }
                    Text("Thử kết nối lại")
                }
                .disabled(vm.isSubmitting)
            }
            
            Section("Cấu hình API") {
                TextField("http://localhost:3001", text: Binding(
                    get: { vm.baseURL },
                    set: { vm.baseURL = $0 }
                ))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                
                Button("Lưu địa chỉ") {
                    Task { await vm.saveBaseURL() }
                }
            }
            
            Section(header: Text("Hàng chờ đồng bộ (\(vm.pendingOps.count))")) {
                if vm.pendingOps.isEmpty {
                    Text("Không có yêu cầu nào đang chờ").font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(vm.pendingOps, id: \.id) { op in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(op.operationType.uppercased())
                                    .font(.caption).bold()
                                    .foregroundStyle(op.operationType == "delete" ? .red : .blue)
                                Text("ID: \(op.entityId)").font(.system(.caption2, design: .monospaced))
                            }
                            Spacer()
                            Button(role: .destructive) {
                                vm.deletePendingOp(op)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Máy chủ")
        .onAppear { vm.refreshPendingOps() }
    }
}

struct DefaultSettingsView: View {
    @Environment(AppViewModel.self) private var app
    
    // Đã thay đổi từ `let vm` sang `@Bindable var vm` để cho phép binding ($vm)
    @Bindable var vm: SettingsViewModel
    
    var body: some View {
        List {
            Section("Giao dịch & Tài khoản") {
                // 1. Loại giao dịch mặc định
                HStack {
                    Label("Loại giao dịch", systemImage: "arrow.left.arrow.right")
                        .layoutPriority(1)
                    
                    Spacer(minLength: 20)
                    
                    Menu {
                        Picker("", selection: Binding(
                            get: { app.defaultTransactionType },
                            set: { newValue in Task { await vm.updateDefaultType(newValue) } }
                        )) {
                            Text("Chi tiêu").tag(TransactionType.expense)
                            Text("Thu nhập").tag(TransactionType.income)
                        }
                    } label: {
                        let selectedName = app.defaultTransactionType == .expense ? "Chi tiêu" : "Thu nhập"
                        HStack(spacing: 4) {
                            Text(selectedName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                // 2. Tài khoản mặc định
                entityMenuRow(
                    title: "Tài khoản",
                    systemImage: "wallet.pass.fill",
                    selectedValue: app.defaultAccountId,
                    options: app.accounts.map { ($0.id, $0.name) }
                ) { newValue in
                    Task { await vm.updateDefaultAccount(newValue ?? "") }
                }
            }
            
            Section("Ngân sách") {
                // 3. Ghim ngân sách
                entityMenuRow(
                    title: "Ghim ngân sách",
                    systemImage: "pin.fill",
                    selectedValue: app.pinnedBudgetId,
                    options: app.budgets.map { ($0.id, $0.name) }
                ) { newValue in
                    Task { await vm.updatePinnedBudgetId(newValue ?? "") }
                }
            }

            Section("Danh mục") {
                // 4. Danh mục chi mặc định
                entityMenuRow(
                    title: "Chi tiêu",
                    systemImage: "arrow.up.circle.fill",
                    color: .red,
                    selectedValue: app.defaultExpenseCategoryId,
                    options: vm.expenseCategories.map { ($0.id, $0.name) }
                ) { newValue in
                    Task { await vm.updateDefaultExpenseCategory(newValue ?? "") }
                }

                // 5. Danh mục thu mặc định
                entityMenuRow(
                    title: "Thu nhập",
                    systemImage: "arrow.down.circle.fill",
                    color: .green,
                    selectedValue: app.defaultIncomeCategoryId,
                    options: vm.incomeCategories.map { ($0.id, $0.name) }
                ) { newValue in
                    Task { await vm.updateDefaultIncomeCategory(newValue ?? "") }
                }
            }
            
            // MARK: - Cài đặt Ego Mode (Khiêm tốn / Tự cao)
            Section(
                header: Text("Ego Mode"),
                footer: Text("Số tiền hiển thị trên giao diện")
            ) {
                HStack {
                    Label("Hệ số Khiêm tốn", systemImage: "tortoise")
                    Spacer()
                    TextField("3.0", text: $vm.humbleFactor)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .onChange(of: vm.humbleFactor) { oldValue, newValue in
                            Task { await vm.saveSettings() }
                        }
                }
                
                HStack {
                    Label("Hệ số Tự cao", systemImage: "crown")
                    Spacer()
                    TextField("3.0", text: $vm.arrogantFactor)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .onChange(of: vm.arrogantFactor) { oldValue, newValue in
                            Task { await vm.saveSettings() }
                        }
                }
            }
        }
        .navigationTitle("Cài đặt mặc định")
    }

    // MARK: - Helper Components
    
    @ViewBuilder
    private func entityMenuRow(
        title: String,
        systemImage: String,
        color: Color = .primary,
        selectedValue: String?,
        options: [(id: String, name: String)],
        onSelect: @escaping (String?) -> Void
    ) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(color)
                .layoutPriority(1)
            
            Spacer(minLength: 20)
            
            Menu {
                // Sử dụng Binding String? kết hợp với tag(String?.none) / tag(String?.some)
                Picker("", selection: Binding<String?>(
                    get: { (selectedValue == nil || selectedValue?.isEmpty == true) ? nil : selectedValue },
                    set: { onSelect($0) }
                )) {
                    Text("— Không chọn —").tag(String?.none)
                    ForEach(options, id: \.id) { opt in
                        Text(opt.name).tag(String?.some(opt.id))
                    }
                }
            } label: {
                let selectedName = options.first(where: { $0.id == selectedValue })?.name ?? "— Không chọn —"
                
                HStack(spacing: 4) {
                    Text(selectedName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
