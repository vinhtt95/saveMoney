import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var scheme
    @StateObject private var vm = TransactionViewModel()

    let editingTransaction: Transaction?

    @State private var amountString: String = "0"
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategoryId: String? = nil
    @State private var selectedAccountId: String? = nil
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""

    @FocusState private var amountFocused: Bool
    @State private var showCategorySheet = false
    @State private var showAccountSheet = false
    @State private var showDateSheet = false
    @State private var showDeleteConfirm = false

    init(isPresented: Binding<Bool>, transaction: Transaction? = nil) {
        self._isPresented = isPresented
        self.editingTransaction = transaction

        if let tx = transaction {
            let absAmount = abs(tx.amount)
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            var amtStr = formatter.string(from: NSNumber(value: absAmount)) ?? String(Int(absAmount))
            amtStr = amtStr.filter { $0.isNumber }
            if amtStr.isEmpty { amtStr = "0" }

            _amountString = State(initialValue: amtStr)
            _selectedType = State(initialValue: tx.type)
            _selectedCategoryId = State(initialValue: tx.categoryId)
            _selectedAccountId = State(initialValue: tx.accountId)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.date(from: tx.date) ?? Date()
            _selectedDate = State(initialValue: date)
            _note = State(initialValue: tx.note ?? "")
        }
    }

    private var filteredCategories: [Category] {
        switch selectedType {
        case .expense: return appVM.expenseCategories
        case .income:  return appVM.incomeCategories
        default:       return appVM.categories
        }
    }

    private var selectedCategoryName: String? {
        selectedCategoryId.flatMap { appVM.category(for: $0)?.name }
    }

    private var selectedAccountName: String? {
        selectedAccountId.flatMap { appVM.account(for: $0)?.name }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        amountCard
                            .padding(.horizontal, 20)

                        typeSelector
                            .padding(.horizontal, 20)

                        formRows
                            .padding(.horizontal, 20)

                        noteField
                            .padding(.horizontal, 20)

                        if editingTransaction != nil {
                            deleteButton
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            if editingTransaction == nil {
                applyDefaults()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                amountFocused = true
            }
        }
        .confirmationDialog("Xóa giao dịch này?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Xóa", role: .destructive) {
                guard let tx = editingTransaction else { return }
                Task {
                    await vm.delete(id: tx.id, appVM: appVM)
                    if vm.submitError == nil {
                        isPresented = false
                    }
                }
            }
            Button("Hủy", role: .cancel) {}
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryPickerSheet(
                categories: filteredCategories,
                selectedId: $selectedCategoryId,
                isPresented: $showCategorySheet
            )
            .environmentObject(appVM)
        }
        .sheet(isPresented: $showAccountSheet) {
            AccountPickerSheet(
                accounts: appVM.accounts,
                selectedId: $selectedAccountId,
                isPresented: $showAccountSheet
            )
            .environmentObject(appVM)
        }
        .sheet(isPresented: $showDateSheet) {
            DatePickerSheet(selectedDate: $selectedDate, isPresented: $showDateSheet)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            Spacer()
            VStack(spacing: 1) {
                Text("TRANSACTION")
                    .font(.dsBody(10, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .tracking(1)
                Text(editingTransaction != nil ? "Edit Entry" : "New Entry")
                    .font(.dsTitle(16))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
            }
            Spacer()
            Button(action: save) {
                Image(systemName: vm.isSubmitting ? "ellipsis" : "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary(for: scheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .disabled(vm.isSubmitting || amountString == "0")
        }
    }

    // MARK: - Amount Card

    private var amountCard: some View {
        GlassCard(radius: DSRadius.xl, padding: 28) {
            ZStack {
                VStack(spacing: 6) {
                    Text("AMOUNT")
                        .font(.dsBody(10, weight: .semibold))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .tracking(1.5)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("₫")
                            .font(.dsDisplay(24))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        Text(amountString == "0" ? "0" : formattedAmount)
                            .font(.dsDisplay(48))
                            .foregroundStyle(Color.dsOnSurface(for: scheme))
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                    }

                    if vm.submitError != nil {
                        Text(vm.submitError!)
                            .font(.dsBody(12))
                            .foregroundStyle(Color.dsExpense)
                    }
                }
                .frame(maxWidth: .infinity)

                // Hidden text field that drives the iOS numeric keyboard
                TextField("", text: Binding(
                    get: { amountString },
                    set: { newVal in
                        let digits = newVal.filter { $0.isNumber }
                        if digits.isEmpty {
                            amountString = "0"
                        } else {
                            // Strip leading zeros
                            let stripped = String(digits.drop(while: { $0 == "0" }))
                            amountString = stripped.isEmpty ? "0" : String(stripped.prefix(12))
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .focused($amountFocused)
                .opacity(0.01)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(action: save) {
                            Text(vm.isSubmitting ? "Đang lưu..." : (editingTransaction != nil ? "Cập nhật →" : "Lưu →"))
                                .font(.dsBody(15, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(LinearGradient.dsCTAGradient(scheme: scheme)))
                        }
                        .disabled(vm.isSubmitting || amountString == "0")
                    }
                }
            }
        }
        .onTapGesture {
            amountFocused = true
        }
    }

    private var formattedAmount: String {
        guard let value = Double(amountString) else { return amountString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? amountString
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        Picker("Loại giao dịch", selection: Binding(
            get: { selectedType },
            set: { newType in
                withAnimation { selectedType = newType }
                selectedCategoryId = nil
                // re-apply default category for new type after state updates
                DispatchQueue.main.async { applyDefaultCategory() }
            }
        )) {
            Text("Chi tiêu").tag(TransactionType.expense)
            Text("Thu nhập").tag(TransactionType.income)
            Text("Chuyển").tag(TransactionType.transfer)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Form Rows

    private var formRows: some View {
        GlassCard(radius: DSRadius.lg, padding: 0) {
            VStack(spacing: 0) {
                formRow(
                    icon: "tag.fill",
                    iconColor: Color.dsPrimary(for: scheme),
                    label: "Category",
                    value: selectedCategoryName ?? "Select",
                    hasValue: selectedCategoryId != nil
                ) {
                    amountFocused = false
                    showCategorySheet = true
                }

                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.4)

                formRow(
                    icon: "creditcard.fill",
                    iconColor: Color(UIColor.systemTeal),
                    label: "Account",
                    value: selectedAccountName ?? "Select",
                    hasValue: selectedAccountId != nil
                ) {
                    amountFocused = false
                    showAccountSheet = true
                }

                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.4)

                formRow(
                    icon: "calendar",
                    iconColor: Color(UIColor.systemOrange),
                    label: "Date",
                    value: formattedDate,
                    hasValue: true
                ) {
                    amountFocused = false
                    showDateSheet = true
                }
            }
        }
    }

    private func formRow(icon: String, iconColor: Color, label: String, value: String, hasValue: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(label)
                    .font(.dsBody(15))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))

                Spacer()

                Text(value)
                    .font(.dsBody(15, weight: hasValue ? .medium : .regular))
                    .foregroundStyle(hasValue ? Color.dsOnSurface(for: scheme) : Color.dsOnSurfaceVariant(for: scheme))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme).opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Field

    private var noteField: some View {
        GlassCard(radius: DSRadius.lg, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    Text("Note")
                        .font(.dsBody(15))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                }

                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Optional...")
                            .font(.dsBody(14))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme).opacity(0.6))
                            .padding(.top, 2)
                    }
                    TextEditor(text: $note)
                        .font(.dsBody(14))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 72)
                }
            }
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text("Xóa giao dịch")
                    .font(.dsBody(16, weight: .semibold))
            }
            .foregroundStyle(Color.dsExpense)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .fill(Color.dsExpense.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                            .stroke(Color.dsExpense.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(vm.isSubmitting)
    }

    // MARK: - Defaults

    private func applyDefaults() {
        if let typeRaw = appVM.settings["default_transaction_type"],
           let type = TransactionType(rawValue: typeRaw.capitalized) {
            selectedType = type
        }
        if let accId = appVM.settings["default_account_id"], !accId.isEmpty {
            selectedAccountId = accId
        }
        applyDefaultCategory()
    }

    private func applyDefaultCategory() {
        let key = selectedType == .income ? "default_income_category_id" : "default_expense_category_id"
        if let catId = appVM.settings[key], !catId.isEmpty,
           appVM.category(for: catId) != nil {
            selectedCategoryId = catId
        }
    }

    // MARK: - Prefill from existing transaction

    private func applyFromTransaction(_ tx: Transaction) {
        let absAmount = abs(tx.amount)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        amountString = formatter.string(from: NSNumber(value: absAmount)) ?? String(Int(absAmount))
        // strip any group separators so it's pure digits
        amountString = amountString.filter { $0.isNumber }
        if amountString.isEmpty { amountString = "0" }

        selectedType = tx.type
        selectedCategoryId = tx.categoryId
        selectedAccountId = tx.accountId

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let d = dateFormatter.date(from: tx.date) {
            selectedDate = d
        }
        note = tx.note ?? ""
    }

    // MARK: - Save

    private func save() {
        guard let amount = Double(amountString), amount > 0 else { return }
        let signedAmount = selectedType == .expense ? -abs(amount) : abs(amount)
        if let tx = editingTransaction {
            let body = UpdateTransactionRequest(
                date: Formatters.toDateString(selectedDate),
                type: selectedType,
                categoryId: selectedCategoryId,
                accountId: selectedAccountId,
                transferToId: nil,
                amount: signedAmount,
                note: note.isEmpty ? nil : note
            )
            Task {
                await vm.update(id: tx.id, body: body, appVM: appVM)
                if vm.submitError == nil {
                    isPresented = false
                }
            }
        } else {
            let body = CreateTransactionRequest(
                date: Formatters.toDateString(selectedDate),
                type: selectedType,
                categoryId: selectedCategoryId,
                accountId: selectedAccountId,
                transferToId: nil,
                amount: signedAmount,
                note: note.isEmpty ? nil : note
            )
            Task {
                await vm.create(body, appVM: appVM)
                if vm.submitError == nil {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.colorScheme) var scheme
    let categories: [Category]
    @Binding var selectedId: String?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader(title: "Category")

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(categories) { cat in
                            categoryRow(cat)
                            if cat.id != categories.last?.id {
                                Divider().padding(.horizontal, 20).opacity(0.4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .background {
                        RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func categoryRow(_ cat: Category) -> some View {
        Button {
            selectedId = cat.id
            isPresented = false
        } label: {
            HStack(spacing: 14) {
                GradientCircleIcon(
                    systemName: categorySystemIcon(for: cat.name),
                    colors: categoryIconColors(for: cat.name),
                    size: 36
                )
                Text(cat.name)
                    .font(.dsBody(15))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                Spacer()
                if selectedId == cat.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dsPrimary(for: scheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func sheetHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.dsTitle(18))
                .foregroundStyle(Color.dsOnSurface(for: scheme))
            Spacer()
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Account Picker Sheet

struct AccountPickerSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.colorScheme) var scheme
    let accounts: [Account]
    @Binding var selectedId: String?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader(title: "Account")

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(accounts) { acc in
                            accountRow(acc)
                            if acc.id != accounts.last?.id {
                                Divider().padding(.horizontal, 20).opacity(0.4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .background {
                        RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func accountRow(_ acc: Account) -> some View {
        Button {
            selectedId = acc.id
            isPresented = false
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(UIColor.systemTeal), Color(UIColor.systemTeal).opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(acc.name)
                        .font(.dsBody(15))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    let balance = appVM.balance(for: acc.id)
                    Text(Formatters.formatVND(balance))
                        .font(.dsBody(12))
                        .foregroundStyle(balance >= 0 ? Color.dsIncome : Color.dsExpense)
                }
                Spacer()
                if selectedId == acc.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dsPrimary(for: scheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func sheetHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.dsTitle(18))
                .foregroundStyle(Color.dsOnSurface(for: scheme))
            Spacer()
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.colorScheme) var scheme
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Select Date")
                        .font(.dsTitle(18))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

                GlassCard(radius: DSRadius.xl, padding: 16) {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(Color.dsPrimary(for: scheme))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                GlassPillButton(label: "Confirm") {
                    isPresented = false
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
