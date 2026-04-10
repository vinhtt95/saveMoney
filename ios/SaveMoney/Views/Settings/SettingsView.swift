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
                    // Giao diện
                    HStack {
                        Label { Text("Giao diện").lineLimit(1) } icon: { Image(systemName: "paintbrush.fill") }
                        Spacer()
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

                    // Địa chỉ máy chủ
                    NavigationLink(destination: serverSettingsView) {
                        Label { Text("Địa chỉ máy chủ").lineLimit(1) } icon: { Image(systemName: "server.rack") }
                    }

                    // Cài đặt mặc định
                    Group {
                        // Loại giao dịch
                        Picker(selection: Binding(
                            get: { app.defaultTransactionType },
                            set: { newValue in Task { await vm.updateDefaultType(newValue) } }
                        )) {
                            Text("Chi tiêu").tag(TransactionType.expense)
                            Text("Thu nhập").tag(TransactionType.income)
                        } label: {
                            Label { Text("Loại GD mặc định").lineLimit(1) } icon: { Image(systemName: "arrow.left.arrow.right") }
                        }

                        // TÀI KHOẢN MẶC ĐỊNH - Giải pháp fix lỗi nhảy dòng
                        HStack {
                            Label {
                                Text("Tài khoản mặc định").lineLimit(1)
                            } icon: {
                                Image(systemName: "wallet.pass.fill")
                            }
                            
                            Spacer(minLength: 20)
                            
                            Picker("", selection: Binding(
                                get: { app.defaultAccountId ?? "" },
                                set: { newValue in Task { await vm.updateDefaultAccount(newValue) } }
                            )) {
                                Text("— Không chọn —").tag("")
                                ForEach(app.accounts) { acc in
                                    Text(acc.name).tag(acc.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden() // Ẩn label của picker để tự kiểm soát không gian
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true) // Ép không giãn chiều dọc
                            .truncationMode(.middle)
                        }
                        
                        // Danh mục mặc định
                        NavigationLink(destination: DefaultCategoriesSettingsView(vm: vm)) {
                            Label { Text("Danh mục mặc định").lineLimit(1) } icon: { Image(systemName: "folder.fill") }
                        }
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if settingsVM == nil { settingsVM = SettingsViewModel(app: app) }
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

// MARK: - View chọn danh mục mặc định (Đã fix nhảy dòng)
struct DefaultCategoriesSettingsView: View {
    let vm: SettingsViewModel
    @Environment(AppViewModel.self) private var app
    
    var body: some View {
        List {
            Section("Danh mục chi mặc định") {
                categoryPicker(title: "Chi tiêu",
                               systemImage: "arrow.up.circle.fill",
                               color: .red,
                               selection: Binding(
                                   get: { app.defaultExpenseCategoryId ?? "" },
                                   set: { newValue in Task { await vm.updateDefaultExpenseCategory(newValue) } }
                               ),
                               categories: vm.expenseCategories)
            }

            Section("Danh mục thu mặc định") {
                categoryPicker(title: "Thu nhập",
                               systemImage: "arrow.down.circle.fill",
                               color: .green,
                               selection: Binding(
                                   get: { app.defaultIncomeCategoryId ?? "" },
                                   set: { newValue in Task { await vm.updateDefaultIncomeCategory(newValue) } }
                               ),
                               categories: vm.incomeCategories)
            }
        }
        .navigationTitle("Danh mục mặc định")
    }

    @ViewBuilder
    private func categoryPicker(title: String, systemImage: String, color: Color, selection: Binding<String>, categories: [Category]) -> some View {
        HStack {
            Label {
                Text(title).lineLimit(1)
            } icon: {
                Image(systemName: systemImage)
            }
            .foregroundStyle(color)
            
            Spacer(minLength: 20)
            
            Picker("", selection: selection) {
                Text("— Không chọn —").tag("")
                ForEach(categories, id: \.id) { category in
                    Text("\(category.name)").tag(category.id as String?)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .lineLimit(1)
            .truncationMode(.tail)
        }
    }
}
