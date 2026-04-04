import SwiftUI

struct CategoryFormView: View {
    @Environment(AppViewModel.self) private var app
    let category: Category?
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var type: CategoryType = .expense
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    private var isEditMode: Bool { category != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin") {
                    TextField("Tên danh mục", text: $name)
                    if !isEditMode {
                        Picker("Loại", selection: $type) {
                            ForEach(CategoryType.allCases, id: \.self) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) }
                }
            }
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
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
        }
        .onAppear {
            name = category?.name ?? ""
            type = category?.type ?? .expense
        }
    }

    private func handleSubmit() async {
        isSubmitting = true
        errorMessage = nil
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        do {
            if let cat = category {
                try await app.updateCategory(cat.id, CategoryUpdateDTO(name: trimmed))
            } else {
                try await app.addCategory(CategoryCreateDTO(name: trimmed, type: type.rawValue))
            }
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
