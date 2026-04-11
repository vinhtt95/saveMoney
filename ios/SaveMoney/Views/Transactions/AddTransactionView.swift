import SwiftUI

struct AddTransactionView: View {
    @Environment(AppViewModel.self) private var app
    let transaction: Transaction?
    let onDismiss: () -> Void
    
    @State private var type: TransactionType = .expense
    @State private var amountText = ""
    @State private var categoryId: String? = nil
    @State private var accountId: String? = nil
    @State private var transferToId: String? = nil
    @State private var date = Date()
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    @State private var isServerReachable: Bool = true
    
    private enum Field {
        case amount
        case note
    }
    @FocusState private var focusedField: Field?
    
    private var isEditMode: Bool { transaction != nil }
    private var title: String { isEditMode ? "Sửa giao dịch" : "Thêm giao dịch" }
    
    // Chuyển text sang số: Loại bỏ dấu chấm phân cách trước khi convert
    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var availableCategories: [Category] {
        switch type {
        case .expense: app.expenseCategories
        case .income: app.incomeCategories
        default: app.categories
        }
    }
    
    private var projectedBalance: Double? {
        guard let accId = accountId else { return nil }
        
        // Lấy số dư hiện tại của tài khoản (bao gồm cả các giao dịch đã lưu)
        let currentBalance = app.computedBalance(for: accId)
        
        // Tính toán ảnh hưởng của giá trị đang nhập trên màn hình
        // Chi tiêu và Chuyển khoản (từ nguồn) sẽ làm giảm số dư
        let newImpact = (type == .expense || type == .transfer) ? -amount : amount
        
        if let tx = transaction, tx.accountId == accId {
            // Trường hợp ĐANG SỬA giao dịch cũ và không đổi tài khoản:
            // Số dư hiện tại (currentBalance) đã bao gồm giá trị cũ của chính giao dịch này.
            // Ta cần: [Số dư] - [Giá trị cũ] + [Giá trị mới đang nhập]
            let oldImpact = (tx.type == .expense || tx.type == .transfer) ? -abs(tx.amount) : tx.amount
            return currentBalance - oldImpact + newImpact
        } else {
            // Trường hợp THÊM MỚI hoặc ĐỔI sang tài khoản khác:
            // Đơn giản là lấy số dư của tài khoản đó cộng thêm giá trị mới
            return currentBalance + newImpact
        }
    }
    
    var body: some View {
        ZStack{
            LiquiBackgroundViewNotAnimating()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Field lớn nhập giá trị - Căn giữa và sát chữ ₫
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Spacer()
                                TextField("0", text: $amountText)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .amount)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .fixedSize() // Giúp TextField chỉ rộng vừa đủ nội dung để ₫ sát vào
                                    .onChange(of: amountText) { _, newValue in
                                        formatAmountInput(newValue)
                                    }
                                
                                Text("₫")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            if let balance = projectedBalance {
                                Text("Sau GD: \(formatBalance(balance))")
                                    .font(.subheadline)
                                    .foregroundStyle(balance < 0 ? .red : .secondary)
                            }
                        }
                        .padding(.vertical, 30)
                        
                        // 2. Toggle switch chọn mode
                        Picker("Loại", selection: $type) {
                            Text("Chi tiêu").tag(TransactionType.expense)
                            Text("Thu nhập").tag(TransactionType.income)
                            Text("Chuyển khoản").tag(TransactionType.transfer)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: type) { _, newValue in
                            if !isEditMode {
                                categoryId = newValue == .expense ? app.defaultExpenseCategoryId : app.defaultIncomeCategoryId
                            }
                        }
                        
                        // 3. Card chi tiết
                        VStack(spacing: 0) {
                            if type != .transfer {
                                HStack {
                                    Label("Danh mục", systemImage: "grid")
                                        .layoutPriority(1) // Giữ cho nhãn không bị thu hẹp
                                    
                                    Spacer(minLength: 10)
                                    
                                    // Sử dụng Menu bọc ngoài Picker để kiểm soát UI hiển thị
                                    Menu {
                                        Picker("", selection: $categoryId) {
                                            Text("Chọn danh mục").tag(String?.none)
                                            ForEach(availableCategories) { cat in
                                                Text(cat.name).tag(String?.some(cat.id))
                                            }
                                        }
                                    } label: {
                                        // Tìm tên danh mục đang chọn để hiển thị
                                        let selectedName = app.categories.first(where: { $0.id == categoryId })?.name ?? "Chọn danh mục"
                                        
                                        HStack(spacing: 4) {
                                            Text(selectedName)
                                                .lineLimit(1) // Ép hiển thị trên 1 dòng
                                                .truncationMode(.tail) // Thêm dấu ... nếu tên quá dài
                                            
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .trailing) // Căn lề phải
                                    }
                                }
                                .padding()
                                Divider().padding(.leading, 44)
                            }
                            
                            HStack {
                                Label("Tài khoản", systemImage: "creditcard")
                                    .layoutPriority(1) // Đảm bảo Label không bị thu hẹp
                                
                                Spacer(minLength: 10)
                                
                                // Dùng Menu bọc ngoài Picker
                                Menu {
                                    Picker("", selection: $accountId) {
                                        Text("Chọn tài khoản").tag(String?.none)
                                        ForEach(app.accounts) { acc in
                                            Text(acc.name).tag(String?.some(acc.id))
                                        }
                                    }
                                } label: {
                                    // --- BẮT ĐẦU PHẦN CUSTOM UI HIỂN THỊ ---
                                    // Lấy tên của tài khoản đang được chọn để hiển thị, nếu null thì hiện mặc định
                                    let selectedName = app.accounts.first(where: { $0.id == accountId })?.name ?? "Chọn tài khoản"
                                    
                                    HStack(spacing: 4) {
                                        Text(selectedName)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        
                                        // Thêm icon mũi tên cho giống với Picker mặc định của iOS
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                    }
                                    // Cho phép phần label này chiếm hết không gian còn lại và căn phải
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .padding()
                            
                            if type == .transfer {
                                Divider().padding(.leading, 44)
                                HStack {
                                    Label("Đến", systemImage: "arrow.right.circle")
                                        .layoutPriority(1) // Đảm bảo Label không bị thu hẹp
                                    
                                    Spacer(minLength: 10)
                                    
                                    // Dùng Menu bọc ngoài Picker giống hệt dòng Tài khoản
                                    Menu {
                                        Picker("", selection: $transferToId) {
                                            Text("Chọn tài khoản").tag(String?.none)
                                            ForEach(app.accounts.filter { $0.id != accountId }) { acc in
                                                Text(acc.name).tag(String?.some(acc.id))
                                            }
                                        }
                                    } label: {
                                        // Custom UI để luôn hiển thị 1 dòng
                                        let selectedName = app.accounts.first(where: { $0.id == transferToId })?.name ?? "Chọn tài khoản"
                                        
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
                                .padding()
                            }
                            
                            Divider().padding(.leading, 44)
                            
                            DatePicker(selection: $date, displayedComponents: .date) {
                                Label("Ngày", systemImage: "calendar")
                            }
                            .padding()
                            .environment(\.locale, Locale(identifier: "vi_VN"))
                        }
                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                        .padding(.horizontal)
                        
                        // 4. Card ghi chú
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Ghi chú", systemImage: "pencil.and.outline")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextField("Nhập ghi chú...", text: $note, axis: .vertical)
                                .lineLimit(3...5)
                                .focused($focusedField, equals: .note)
                        }
                        .padding()
                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                        .padding(.horizontal)
                        
                        if let errorMessage {
                            ErrorBanner(message: errorMessage)
                                .padding(.horizontal)
                        }
                        
                        if isEditMode {
                            Button(role: .destructive) {
                                Task { await handleDelete() }
                            } label: {
                                Label("Xóa giao dịch", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .background(LiquiBackgroundViewNotAnimating())
                .navigationTitle(title)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Hủy") { onDismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditMode ? "Lưu" : "Thêm") {
                            Task { await handleSubmit() }
                        }
                        .fontWeight(.bold)
                        .disabled(amount <= 0 || isSubmitting)
                    }
                    
                    // Toolbar hỗ trợ nhập nhanh trên bàn phím
                    ToolbarItemGroup(placement: .keyboard) {
                        if focusedField == .amount {
                            HStack(spacing: 16) {
                                if amount == 0 {
                                    // Gợi ý mặc định khi chưa có giá trị
                                    Button("5K") { formatAmountInput("5000") }.padding(.vertical ,5)
                                    Button("30K") { formatAmountInput("30000") }.padding(.vertical ,5)
                                    Button("35K") { formatAmountInput("35000") }.padding(.vertical ,5)
                                    Button("300K") { formatAmountInput("300000") }.padding(.vertical ,5)
                                } else {
                                    // Gợi ý động dựa trên số gốc (significant digits)
                                    let baseValue: Double = {
                                        var val = Int(amount)
                                        while val >= 10 && val % 10 == 0 { val /= 10 }
                                        return Double(val)
                                    }()
                                    
                                    let targets: [Double] = [
                                        baseValue * 1_000,
                                        baseValue * 10_000,
                                        baseValue * 100_000
                                    ]
                                    
                                    ForEach(targets, id: \.self) { target in
                                        // Giới hạn gợi ý tối đa 900.000 như bạn yêu cầu
                                        if target <= 900_000 {
                                            Button(formatVNDShort(target).replacingOccurrences(of: "₫", with: "")) {
                                                formatAmountInput(String(Int(target)))
                                            }.padding(.vertical ,5)
                                        }
                                    }
                                }
                            }
                            //                        .background(.bar.opacity(0.5), in: .capsule)
                            .glassEffect()
                            //                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                            .padding(.bottom, 10)
                            .font(.system(.callout, design: .monospaced))
                            Spacer()
                            Spacer()
                        }
                    }
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarItemGroup(placement: .keyboard){
                        if focusedField != .amount {
                            Spacer()
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard){
                        HStack(spacing: 16){
                            
                            Button("Xong") {
                                focusedField = nil
                            }
                            .padding(.vertical ,5)
                            .fontWeight(.bold)
                        }
                        .glassEffect()
                        .padding(.bottom, 10)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
            }
            .onAppear {
                prefill()
                Task {
                    isServerReachable = await app.checkServerReachability()
                    if !isServerReachable {
                        print("🔴 Mất kết nối tới Server. Các thao tác sẽ được lưu vào hàng đợi Offline ngay lập tức.")
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    focusedField = .amount
                }
            }
        }
    }
    
    // Định dạng dấu chấm khi người dùng gõ
    private func formatAmountInput(_ input: String) {
        let clean = input.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")
        guard let number = Double(clean) else {
            if clean.isEmpty { amountText = "" }
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        if let formatted = formatter.string(from: NSNumber(value: number)) {
            // Chỉ cập nhật nếu khác biệt để tránh loop vô tận
            if amountText != formatted {
                amountText = formatted
            }
        }
    }
    
    private func appendZeros(_ count: Int) {
        let clean = amountText.replacingOccurrences(of: ".", with: "")
        let suffix = String(repeating: "0", count: count)
        formatAmountInput(clean + suffix)
    }
    
    private func prefill() {
        if let tx = transaction {
            type = tx.type
            formatAmountInput(String(Int(abs(tx.amount))))
            categoryId = tx.categoryId
            accountId = tx.accountId
            transferToId = tx.transferToId
            date = parseStorageDate(tx.date) ?? Date()
            note = tx.note ?? ""
        } else {
            type = app.defaultTransactionType
            accountId = app.defaultAccountId
            categoryId = type == .expense ? app.defaultExpenseCategoryId : app.defaultIncomeCategoryId
            date = Date()
        }
    }
    
    private func handleSubmit() async {
        isSubmitting = true
        errorMessage = nil
        
        let storageDateString = toStorageString(date)
        let dto = TransactionCreateDTO(
            date: storageDateString,
            type: type.rawValue,
            categoryId: categoryId,
            accountId: accountId,
            transferToId: transferToId,
            amount: type == .expense ? -amount : amount,
            note: note.isEmpty ? nil : note
        )
        do {
            if let tx = transaction {
                // Truyền forceOffline dựa vào kết quả Ping ban nãy
                try await app.updateTransaction(tx.id, dto, forceOffline: !isServerReachable)
            } else {
                // Truyền forceOffline dựa vào kết quả Ping ban nãy
                try await app.addTransaction(dto, forceOffline: !isServerReachable)
            }
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
    
    private func handleDelete() async {
        guard let tx = transaction else { return }
        isSubmitting = true
        do {
            // Truyền forceOffline dựa vào kết quả Ping ban nãy
            try await app.deleteTransaction(tx.id, forceOffline: !isServerReachable)
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
