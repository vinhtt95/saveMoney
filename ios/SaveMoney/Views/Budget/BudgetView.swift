import SwiftUI

struct BudgetView: View {
    @Environment(AppViewModel.self) private var app
    @State private var budgetVM: BudgetViewModel?
    @State private var showAddForm = false
    
    private var vm: BudgetViewModel {
        budgetVM ?? BudgetViewModel(app: app)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if app.budgets.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.doc.horizontal",
                        title: "Chưa có ngân sách",
                        message: "Thêm ngân sách để theo dõi chi tiêu của bạn."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(app.budgets) { budget in
                        // CHUYỂN HƯỚNG THẲNG TỚI FORM TỔNG HỢP
                        NavigationLink(destination: BudgetFormView(budget: budget)) {
                            BudgetProgressRow(budget: budget, vm: vm, app: app)
                                .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await vm.deleteBudget(budget.id) }
                            } label: {
                                Label("Xóa", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ngân sách")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            // HIỆN FORM Ở CHẾ ĐỘ THÊM MỚI BỌC TRONG NAVIGATION STACK
            .sheet(isPresented: $showAddForm) {
                NavigationStack {
                    BudgetFormView(budget: nil)
                }
            }
            .onAppear {
                if budgetVM == nil { budgetVM = BudgetViewModel(app: app) }
            }
        }
    }
}

// MARK: - Add Budget Sheet
struct AddBudgetView: View {
    @Environment(AppViewModel.self) private var app
    let onDismiss: () -> Void
    
    @State private var name = ""
    @State private var limitText = ""
    @State private var dateStart = Date()
    @State private var dateEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedCategoryIds: Set<String> = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    private func storageDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin ngân sách") {
                    TextField("Tên ngân sách", text: $name)
                    HStack {
                        TextField("Hạn mức (VNĐ)", text: $limitText)
                            .keyboardType(.numberPad)
                        Text("₫").foregroundStyle(.secondary)
                    }
                }
                
                Section("Thời gian") {
                    DatePicker("Từ ngày", selection: $dateStart, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "vi_VN"))
                    DatePicker("Đến ngày", selection: $dateEnd, in: dateStart..., displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "vi_VN"))
                }
                
                Section("Danh mục áp dụng") {
                    ForEach(app.expenseCategories) { cat in
                        HStack {
                            CategoryIconView(category: cat, fallbackName: cat.name, size: 24)
                            Text(cat.name)
                            Spacer()
                            if selectedCategoryIds.contains(cat.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DSColors.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCategoryIds.contains(cat.id) {
                                selectedCategoryIds.remove(cat.id)
                            } else {
                                selectedCategoryIds.insert(cat.id)
                            }
                        }
                    }
                }
                
                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) }
                }
            }
            .navigationTitle("Thêm ngân sách")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Thêm") {
                        Task { await handleSubmit() }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || limitText.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func handleSubmit() async {
        isSubmitting = true
        errorMessage = nil
        let limit = Double(limitText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")) ?? 0
        let vm = BudgetViewModel(app: app)
        await vm.addBudget(
            name: name.trimmingCharacters(in: .whitespaces),
            limit: limit,
            dateStart: storageDate(dateStart),
            dateEnd: storageDate(dateEnd),
            categoryIds: Array(selectedCategoryIds)
        )
        if let err = vm.errorMessage {
            errorMessage = err
        } else {
            onDismiss()
        }
        isSubmitting = false
    }
}

struct BudgetFormView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    
    let budget: Budget? // Truyền nil nếu Thêm mới, truyền object nếu Xem/Sửa
    
    @State private var name = ""
    @State private var limitText = ""
    @State private var dateStart = Date()
    @State private var dateEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedCategoryIds: Set<String> = []
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    
    private var isEditMode: Bool { budget != nil }
    private var vm: BudgetViewModel { BudgetViewModel(app: app) }
    
    // Các biến tính toán cho Tiến độ chi tiêu (Chỉ dùng khi có budget)
    private var spent: Double { isEditMode ? vm.spentAmount(budget: budget!) : 0 }
    private var progress: Double { isEditMode ? vm.progress(budget: budget!) : 0 }
    private var remain: Double { isEditMode ? max(0, budget!.limit - spent) : 0 }
    
    private func storageDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    
    private func dateFromStorage(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: str) ?? Date()
    }
    
    private func formatCurrency(_ value: String) -> String {
        // 1. Chỉ lấy các ký tự là số
        let numericString = value.filter { "0123456789".contains($0) }
        guard let number = Int(numericString) else { return "" }
        
        // 2. Format số với dấu chấm phân cách hàng nghìn
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    var body: some View {
        Form {
            // 1. CHỈ HIỂN THỊ KHI XEM/SỬA: Tiến độ chi tiêu
            if isEditMode {
                Section("Tiến độ chi tiêu") {
                    VStack(spacing: 16) {
                        ProgressView(value: min(progress, 1.0))
                            .tint(vm.progressColor(budget: budget!))
                            .scaleEffect(y: 2)
                            .padding(.top, 8)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Đã chi")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatVNDShort(spent))
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(vm.progressColor(budget: budget!))
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Còn lại")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatVNDShort(remain))
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(progress >= 1.0 ? .red : .primary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 2. THÔNG TIN CƠ BẢN (Dùng chung)
            Section("Thông tin ngân sách") {
                TextField("Tên ngân sách (VD: Ăn uống, Giải trí)", text: $name)
                HStack {
                    TextField("Hạn mức (VNĐ)", text: $limitText)
                        .keyboardType(.numberPad)
                    // Lắng nghe sự thay đổi khi người dùng nhập liệu (Dành cho iOS 17+)
                        .onChange(of: limitText) { oldValue, newValue in
                            // Chặn update vòng lặp vô hạn
                            let formatted = formatCurrency(newValue)
                            if limitText != formatted {
                                limitText = formatted
                            }
                        }
                    Text("₫").foregroundStyle(.secondary)
                }
            }
            
            // 3. THỜI GIAN (Dùng chung)
            Section("Thời gian") {
                DatePicker("Từ ngày", selection: $dateStart, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "vi_VN"))
                DatePicker("Đến ngày", selection: $dateEnd, in: dateStart..., displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "vi_VN"))
            }
            
            // 4. DANH MỤC (Dùng chung)
            Section("Áp dụng cho danh mục") {
                ForEach(app.expenseCategories) { cat in
                    HStack {
                        CategoryIconView(category: cat, fallbackName: cat.name, size: 24)
                        Text(cat.name)
                        Spacer()
                        if selectedCategoryIds.contains(cat.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(DSColors.accent)
                                .fontWeight(.bold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) {
                            if selectedCategoryIds.contains(cat.id) {
                                selectedCategoryIds.remove(cat.id)
                            } else {
                                selectedCategoryIds.insert(cat.id)
                            }
                        }
                    }
                }
            }
            
            // 5. HIỂN THỊ LỖI NẾU CÓ
            if let errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // 6. CHỈ HIỂN THỊ KHI XEM/SỬA: Nút Xóa
            if isEditMode {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Xóa ngân sách")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle(isEditMode ? "Chi tiết ngân sách" : "Thêm ngân sách")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Nút "Hủy" chỉ cần khi Thêm mới (nằm trong Sheet)
            ToolbarItem(placement: .topBarLeading) {
                if !isEditMode {
                    Button("Hủy") { dismiss() }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditMode ? "Lưu" : "Thêm") {
                    Task { await handleSubmit() }
                }
                .fontWeight(.bold)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || limitText.isEmpty || selectedCategoryIds.isEmpty || isSubmitting)
            }
        }
        .onAppear {
            if let b = budget {
                name = b.name
                // Gọi hàm format để số tiền lúc vừa mở màn hình cũng có dấu chấm
                limitText = formatCurrency(String(format: "%.0f", b.limit))
                dateStart = dateFromStorage(b.dateStart)
                dateEnd = dateFromStorage(b.dateEnd)
                selectedCategoryIds = Set(b.categoryIds)
            }
        }
        // Popup xác nhận xóa
        .alert("Xóa ngân sách?", isPresented: $showDeleteConfirm) {
            Button("Hủy", role: .cancel) { }
            Button("Xóa", role: .destructive) {
                Task {
                    await vm.deleteBudget(budget!.id)
                    dismiss() // Xóa xong tự động quay về list
                }
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa ngân sách này? Dữ liệu giao dịch sẽ không bị mất.")
        }
    }
    
    private func handleSubmit() async {
        isSubmitting = true
        errorMessage = nil
        let limit = Double(limitText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")) ?? 0
        
        if isEditMode {
            await vm.updateBudget(
                id: budget!.id,
                name: name.trimmingCharacters(in: .whitespaces),
                limit: limit,
                dateStart: storageDate(dateStart),
                dateEnd: storageDate(dateEnd),
                categoryIds: Array(selectedCategoryIds)
            )
        } else {
            await vm.addBudget(
                name: name.trimmingCharacters(in: .whitespaces),
                limit: limit,
                dateStart: storageDate(dateStart),
                dateEnd: storageDate(dateEnd),
                categoryIds: Array(selectedCategoryIds)
            )
        }
        
        if let err = vm.errorMessage {
            errorMessage = err
        } else {
            dismiss() // Lưu xong quay về
        }
        isSubmitting = false
    }
}
