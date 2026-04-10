import SwiftUI

struct CategoryFormView: View {
    @Environment(AppViewModel.self) private var app
    let category: Category?
    let onDismiss: () -> Void
    
    @State private var name = ""
    @State private var type: CategoryType = .expense
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor = "accent"
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    
    private var isEditMode: Bool { category != nil }
    
    // Cấu hình danh sách lựa chọn
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
    let colors = ["orange", "blue", "pink", "purple", "red", "indigo", "green", "teal", "yellow", "brown", "gray", "accent"]
    let icons = ["fork.knife", "car.fill", "cart.fill", "house.fill", "gamecontroller.fill", "airplane", "heart.fill", "book.fill", "banknote.fill", "bolt.fill", "wifi", "tag.fill", "tshirt.fill", "gift.fill", "pills.fill"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Loại danh mục (Segmented Picker)
                Picker("Loại", selection: $type) {
                    ForEach(CategoryType.allCases, id: \.self) { t in
                        Text(t.label).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .disabled(isEditMode) // Reminders không cho đổi loại list sau khi tạo
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 2. Phần xem trước Icon và Tên
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
                            
                            TextField("Tên danh mục", text: $name)
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(CategoryColorHelper.map(selectedColor))
                        }
                        .padding(.vertical, 30)
                        .frame(maxWidth: .infinity)
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
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditMode ? "Sửa danh mục" : "Thêm danh mục")
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
            if let cat = category {
                name = cat.name
                type = cat.type
                selectedIcon = cat.icon
                selectedColor = cat.color
            }
        }
    }
    
    private func handleSubmit() async {
        isSubmitting = true
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        do {
            if let cat = category {
                // Gửi DTO cập nhật bao gồm icon và color
                try await app.updateCategory(cat.id, CategoryUpdateDTO(name: trimmed, icon: selectedIcon, color: selectedColor))
            } else {
                let newId = UUID().uuidString.lowercased()
                
                let dto = CategoryCreateDTO(
                    id: newId,
                    name: trimmed,
                    type: type.rawValue,
                    icon: selectedIcon,
                    color: selectedColor
                )
                try await app.addCategory(dto)
            }
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
