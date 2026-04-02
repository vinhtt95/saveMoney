import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = SettingsViewModel()

    private var defaultType: Binding<String> {
        Binding(
            get: { appVM.settings["default_transaction_type"] ?? "expense" },
            set: { appVM.settings["default_transaction_type"] = $0 }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("http://localhost:3001", text: $vm.baseURL)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        Button("Lưu URL") {
                            vm.saveBaseURL()
                            Task { await appVM.loadInitData() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.baseURL.isEmpty)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Kết nối Backend")
                } footer: {
                    Text("Dùng IP LAN (vd: http://192.168.1.x:3001) khi chạy trên thiết bị thật.")
                }

                Section("Mặc định giao dịch") {
                    Picker("Loại mặc định", selection: defaultType) {
                        Text("Chi tiêu").tag("expense")
                        Text("Thu nhập").tag("income")
                    }

                    Picker("Tài khoản mặc định", selection: Binding(
                        get: { appVM.settings["default_account_id"] ?? "" },
                        set: { appVM.settings["default_account_id"] = $0 }
                    )) {
                        Text("Không chọn").tag("")
                        ForEach(appVM.accounts) { acc in
                            Text(acc.name).tag(String(acc.id))
                        }
                    }

                    Button("Lưu cài đặt mặc định") {
                        Task { await vm.saveDefaults(settings: appVM.settings, appVM: appVM) }
                    }
                    .disabled(vm.isSaving)
                }

                if vm.saveSuccess {
                    Section {
                        Label("Đã lưu thành công", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                if let err = vm.saveError {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }

                Section("Thông tin") {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Backend")
                        Spacer()
                        Text(vm.baseURL)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .navigationTitle("Cài đặt")
        }
    }
}
