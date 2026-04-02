import SwiftUI

struct CategoryFormView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme
    private let api = APIService.shared

    @State private var name = ""
    @State private var type: CategoryType = .expense
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()
                VStack(spacing: 16) {
                    GlassCard(radius: DSRadius.lg, padding: 16) {
                        VStack(spacing: 14) {
                            GlassFormField(label: "Tên danh mục", text: $name)
                            Picker("Loại", selection: $type) {
                                ForEach(CategoryType.allCases, id: \.self) {
                                    Text($0.displayName).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if let err = error {
                        Text(err).font(.dsBody(12)).foregroundStyle(Color.dsExpense)
                            .padding(.horizontal, 20)
                    }

                    GlassPillButton(label: isSubmitting ? "Đang lưu..." : "Lưu") {
                        save()
                    }
                    .disabled(isSubmitting || name.isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Thêm danh mục")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundStyle(Color.dsPrimary(for: scheme))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
