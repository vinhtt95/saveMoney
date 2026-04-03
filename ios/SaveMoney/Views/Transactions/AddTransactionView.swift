import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var scheme
    @StateObject private var vm = TransactionViewModel()

    @State private var amountString: String = "0"
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategoryId: String? = nil
    @State private var selectedAccountId: String? = nil
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""

    private var filteredCategories: [Category] {
        switch selectedType {
        case .expense: return appVM.expenseCategories
        case .income:  return appVM.incomeCategories
        default:       return appVM.categories
        }
    }

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        amountCard.padding(.horizontal, 20)
                        typeSelector.padding(.horizontal, 20)
                        categorySection.padding(.horizontal, 20)
                        accountDateRow.padding(.horizontal, 20)
                        GlassFormField(label: "Ghi chú", text: $note, placeholder: "Tuỳ chọn...")
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
                }

                if let err = vm.submitError {
                    Text(err)
                        .font(.dsBody(12))
                        .foregroundStyle(Color.dsExpense)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }

                keypad
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
            }
            Spacer()
            VStack(spacing: 1) {
                Text("TRANSACTION")
                    .font(.dsBody(10, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .tracking(1)
                Text("New Entry")
                    .font(.dsTitle(16))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
            }
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    // MARK: - Amount Card

    private var amountCard: some View {
        GlassCard(radius: DSRadius.xl, padding: 20) {
            VStack(spacing: 12) {
                Text("AMOUNT")
                    .font(.dsBody(10, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .tracking(1.5)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("₫")
                        .font(.dsDisplay(24))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    Text(amountString)
                        .font(.dsDisplay(42))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    // Date chip with overlay picker
                    ZStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(Formatters.formatDate(Formatters.toDateString(selectedDate)))
                                .font(.dsBody(12))
                        }
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.ultraThinMaterial))

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .opacity(0.011)
                            .frame(width: 110, height: 30)
                    }

                    if let accId = selectedAccountId,
                       let acc = appVM.account(for: accId) {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 12))
                            Text(acc.name)
                                .font(.dsBody(12))
                        }
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.ultraThinMaterial))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach([TransactionType.expense, .income, .transfer], id: \.self) { t in
                let isSelected = selectedType == t
                Button {
                    selectedType = t
                    selectedCategoryId = nil
                } label: {
                    Text(t.displayName)
                        .font(.dsBody(13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : Color.dsOnSurfaceVariant(for: scheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                    .fill(LinearGradient.dsCTAGradient(scheme: scheme))
                            }
                        }
                }
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DSSectionHeader(title: "Category")
            if filteredCategories.isEmpty {
                Text("Chưa có danh mục")
                    .font(.dsBody(13))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                    ForEach(filteredCategories) { cat in
                        let isSelected = selectedCategoryId == cat.id
                        Button {
                            selectedCategoryId = isSelected ? nil : cat.id
                        } label: {
                            VStack(spacing: 6) {
                                GradientCircleIcon(
                                    systemName: categorySystemIcon(for: cat.name),
                                    colors: isSelected
                                        ? categoryIconColors(for: cat.name)
                                        : [Color.dsOnSurfaceVariant(for: scheme).opacity(0.4),
                                           Color.dsOnSurfaceVariant(for: scheme).opacity(0.2)],
                                    size: 36
                                )
                                Text(cat.name)
                                    .font(.dsBody(11, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected
                                                     ? Color.dsPrimary(for: scheme)
                                                     : Color.dsOnSurfaceVariant(for: scheme))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                    .fill(isSelected
                                          ? Color.dsPrimary(for: scheme).opacity(0.12)
                                          : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                            .stroke(isSelected
                                                    ? Color.dsPrimary(for: scheme).opacity(0.4)
                                                    : Color.clear,
                                                    lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Account Row

    private var accountDateRow: some View {
        GlassCard(radius: DSRadius.md, padding: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsPrimary(for: scheme))
                Picker("Tài khoản", selection: Binding(
                    get: { selectedAccountId ?? "" },
                    set: { selectedAccountId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Chọn tài khoản").tag("")
                    ForEach(appVM.accounts) { acc in
                        Text(acc.name).tag(acc.id)
                    }
                }
                .font(.dsBody(13))
                .tint(Color.dsOnSurface(for: scheme))
                .labelsHidden()
                Spacer()
            }
        }
    }

    // MARK: - Keypad

    private enum KeypadKey: Equatable {
        case digit(String), clear, backspace
        var label: String {
            switch self {
            case .digit(let s): return s
            case .clear: return "C"
            case .backspace: return "⌫"
            }
        }
    }

    private var keypad: some View {
        let rows: [[KeypadKey]] = [
            [.digit("1"), .digit("2"), .digit("3")],
            [.digit("4"), .digit("5"), .digit("6")],
            [.digit("7"), .digit("8"), .digit("9")],
            [.clear, .digit("0"), .backspace]
        ]
        return VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    ForEach(rows[i], id: \.label) { key in
                        keyButton(key)
                    }
                }
            }
            GlassPillButton(label: vm.isSubmitting ? "Đang lưu..." : "Lưu giao dịch →") {
                save()
            }
            .disabled(vm.isSubmitting || amountString == "0")
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
    }

    private func keyButton(_ key: KeypadKey) -> some View {
        Button {
            handleKey(key)
        } label: {
            Group {
                if case .backspace = key {
                    Image(systemName: "delete.left")
                        .font(.system(size: 18, weight: .medium))
                } else {
                    Text(key.label)
                        .font(.dsDisplay(22, weight: .medium))
                }
            }
            .foregroundStyle(key == .clear ? Color.dsExpense : Color.dsOnSurface(for: scheme))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                    )
            }
        }
    }

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            if amountString == "0" {
                amountString = d
            } else if amountString.count < 12 {
                amountString += d
            }
        case .clear:
            amountString = "0"
        case .backspace:
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard let amount = Double(amountString), amount > 0 else { return }
        let signedAmount = selectedType == .expense ? -abs(amount) : abs(amount)
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
