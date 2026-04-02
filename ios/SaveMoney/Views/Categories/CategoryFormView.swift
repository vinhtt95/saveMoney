import SwiftUI

struct CategoryFormView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) var dismiss
    private let api = APIService.shared

    @State private var name = ""
    @State private var type: CategoryType = .expense
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin danh mục") {
                    TextField("Tên danh mục", text: $name)
                    Picker("Loại", selection: $type) {
                        ForEach(CategoryType.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if let err = error {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Thêm danh mục")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                        .disabled(isSubmitting || name.isEmpty)
                }
            }
        }
    }

    private func save() {
        isSubmitting = true
        Task {
            do {
                let cat = try await api.createCategory(CreateCategoryRequest(name: name, type: type))
                appVM.categories.append(cat)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
