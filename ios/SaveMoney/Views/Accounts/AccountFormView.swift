import SwiftUI

struct AccountFormView: View {
    @Environment(AppViewModel.self) private var app
    let account: Account?
    let onDismiss: () -> Void
    
    @State private var name = ""
    @State private var balanceText = ""
    @State private var selectedIcon = "creditcard.fill"
    @State private var selectedColor = "accent"
    
    @State private var vm: AccountViewModel?
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    
    private var isEditMode: Bool { account != nil }
    
    // Cấu hình danh sách lựa chọn
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
    let colors = ["orange", "blue", "pink", "purple", "red", "indigo", "green", "teal", "yellow", "brown", "gray", "accent"]
    let icons = AppIcons.allIcons
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. Vùng xem trước Icon và Tên tài khoản
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(CategoryColorHelper.map(selectedColor))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: CategoryColorHelper.map(selectedColor).opacity(0.3), radius: 10, y: 5)
                                
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            TextField("Tên tài khoản", text: $name)
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(CategoryColorHelper.map(selectedColor))
                        }
                        .padding(.vertical, 30)
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // 2. Vùng nhập Số dư (Balance Area - Tách riêng biệt)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SỐ DƯ TÀI KHOẢN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("0", text: $balanceText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("₫")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            Text(isEditMode ? "Cập nhật số dư ban đầu (base balance) của tài khoản." : "Nhập số dư ban đầu khi tạo tài khoản.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // 3. Lưới chọn Màu sắc
                        VStack {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(colors, id: \.self) { colorName in
                                    Circle()
                                        .fill(CategoryColorHelper.map(colorName))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == colorName ? 3 : 0)
                                                .padding(3)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.2), lineWidth: selectedColor == colorName ? 1 : 0)
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring()) { selectedColor = colorName }
                                        }
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // 4. Lưới chọn Biểu tượng
                        VStack {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(icons, id: \.self) { iconName in
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == iconName ? CategoryColorHelper.map(selectedColor) : Color(uiColor: .systemGray6))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: iconName)
                                            .foregroundColor(selectedIcon == iconName ? .white : CategoryColorHelper.map(selectedColor))
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring()) { selectedIcon = iconName }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditMode ? "Sửa tài khoản" : "Thêm tài khoản")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
        }
        .onAppear {
            vm = AccountViewModel(app: app)
            if let acc = account {
                name = acc.name
                selectedIcon = acc.icon
                selectedColor = acc.color
                
                // Lấy đúng số dư ban đầu (base balance) của tài khoản
                balanceText = String(format: "%.0f", acc.balance)
            }
        }
    }
    
    private func handleSubmit() async {
        guard let vm else { return }
        isSubmitting = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        // Lọc bỏ dấu phẩy/chấm nếu người dùng có nhập vào
        let cleanBalanceText = balanceText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
        let balanceValue = Double(cleanBalanceText) ?? 0.0
        
        if let acc = account {
            await vm.updateAccount(id: acc.id, name: trimmedName, balance: balanceValue, icon: selectedIcon, color: selectedColor)
        } else {
            await vm.addAccount(name: trimmedName, initialBalance: balanceValue, icon: selectedIcon, color: selectedColor)
        }
        
        if let err = vm.errorMessage {
            errorMessage = err
            isSubmitting = false
        } else {
            onDismiss()
        }
    }
}
